pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../operator/OperatorPortal.sol";
import "./IPriceSource.sol";

interface IExchangePriceSource {
    struct Price {
        uint256 ask;
        uint256 bid;
    }

    function getPrice(
        address askAssetAddress,
        address bidAssetAddress,
        uint256 timeslot
    ) external view returns (Price memory);
}

contract OperatorPriceSource is IPriceSource, IDelegator, Ownable {
    uint256 constant PRICE_FEED_INTERVAL = 600; // 10 minutes

    OperatorPortal internal _portal;
    IERC20 internal _baseAsset;
    IExchangePriceSource internal _exchange;

    // price: token price denoted by _baseAsset (DAI or ALD)
    struct PriceData {
        address asset;
        address reporter;
        uint256 price;
        uint256 timeslot;
        uint256 timestamp;
        uint256 realTimestamp;
    }

    PriceData[] private _priceDataList;

    // asset => timeSlot => price
    mapping(address => mapping(uint256 => uint256)) private _priceFeed;
    // asset => timeSlot => priceData
    mapping(address => mapping(uint256 => uint256[])) private _priceData;
    // asset => timeSlot
    mapping(address => uint256) private _lastValidTimeslot;
    // asset => timeSlot
    mapping(address => uint256) private _firstValidTimeslot;
    // operator => timeSlot
    mapping(address => uint256) private _lastReportedSlot;
    // asset => timeSlot => isSlashed
    mapping(address => mapping(uint256 => bool)) private _isSlashedTimeslot;
    // asset => operator => timeSlot => price
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _operatorReportedPrice;

    uint256 internal _maxIncrementRate = 10000000000000000; // 0.01;
    uint256 internal _maxExchangeDiffRate = 100000000000000000; // 0.1;
    uint256 internal _penaltyRate = 10000000000000000; // 0.01;

    event OperatorPortalChanged(address indexed from, address indexed to);
    event BaseAssetChanged(address indexed from, address indexed to);
    event ExchangeChanged(address indexed from, address indexed to);
    event MaxIncrementRateChanged(uint256 from, uint256 to);
    event MaxExchangeDiffRateChanged(uint256 from, uint256 to);
    event PenaltyRateChanged(uint256 from, uint256 to);

    modifier onlyOperator(address assetAddress) {
        require(
            _portal.isOperator(msg.sender, assetAddress),
            "caller is not operator"
        );
        _;
    }

    constructor(
        address ownerAddress,
        address portalAddress,
        address baseAssetAddress,
        address exchangeAddress
    ) public {
        _owner = ownerAddress;
        _portal = OperatorPortal(portalAddress);
        _baseAsset = IERC20(baseAssetAddress);
        _exchange = IExchangePriceSource(exchangeAddress);
    }

    function portal() public view returns (OperatorPortal) {
        return _portal;
    }

    function setPortal(OperatorPortal newPortal) public onlyOwner {
        require(address(newPortal) != address(0));

        emit OperatorPortalChanged(address(_portal), address(newPortal));

        _portal = newPortal;
    }

    function baseAsset() public view returns (IERC20) {
        return _baseAsset;
    }

    function setBaseAsset(IERC20 newAsset) public onlyOwner {
        require(address(newAsset) != address(0));

        emit BaseAssetChanged(address(_baseAsset), address(newAsset));

        _baseAsset = newAsset;
    }

    function exchange() public view returns (address) {
        return address(_exchange);
    }

    function setExchange(IExchangePriceSource newExchange) public onlyOwner {
        require(address(newExchange) != address(0));

        emit ExchangeChanged(address(_exchange), address(newExchange));

        _exchange = newExchange;
    }

    function maxIncrementRate() public view returns (uint256) {
        return _maxIncrementRate;
    }

    function setMaxIncrementRate(uint256 newRate) public onlyOwner {
        emit MaxIncrementRateChanged(_maxIncrementRate, newRate);

        _maxIncrementRate = newRate;
    }

    function maxExchangeDiffRate() public view returns (uint256) {
        return _maxExchangeDiffRate;
    }

    function setMaxExchangeDiffRate(uint256 newRate) public onlyOwner {
        emit MaxExchangeDiffRateChanged(_maxExchangeDiffRate, newRate);

        _maxExchangeDiffRate = newRate;
    }

    function penaltyRate() public view returns (uint256) {
        return _penaltyRate;
    }

    function setPenaltyRate(uint256 newRate) public onlyOwner {
        emit PenaltyRateChanged(_penaltyRate, newRate);

        _penaltyRate = newRate;
    }

    function getPrice(address asset, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return _priceFeed[asset][_timestampToTimeslot(timestamp)];
    }

    function getLastPrice(address asset) public view returns (uint256) {
        return _priceFeed[asset][_lastValidTimeslot[asset]];
    }

    function postPrice(address asset, uint256 timestamp, uint256 price)
        public
        onlyOperator(asset)
        returns (bool)
    {
        uint256 timeslot = _timestampToTimeslot(timestamp);
        require(
            timeslot > _lastReportedSlot[msg.sender],
            "cannot post previous slot"
        );
        require(_isValidPrice(asset, price, timeslot), "invalid price");

        uint256 dataId = _priceDataList.length;
        _priceDataList.length += 1;

        _priceDataList[dataId].asset = asset;
        _priceDataList[dataId].reporter = msg.sender;
        _priceDataList[dataId].price = price;
        _priceDataList[dataId].timeslot = timeslot;
        _priceDataList[dataId].timestamp = timestamp;
        _priceDataList[dataId].realTimestamp = block.timestamp;

        _priceData[asset][timeslot].push(dataId);

        emit PriceReported(asset, msg.sender, timeslot, price);

        // if previous timeslot not validated
        if (_lastValidTimeslot[asset] < timeslot - 1) {
            _validatePendingPrices(asset);
        }

        return false;
    }

    function validatePriceSlot(address asset, uint256 timeslot) public {}

    function _validatePendingPrices(address asset) internal returns (bool) {
        uint256 lastTimeslot = _lastValidTimeslot[asset];
        uint256 currentTimeslot = _timestampToTimeslot(block.timestamp);

        for (
            ;
            lastTimeslot < currentTimeslot;
            lastTimeslot += PRICE_FEED_INTERVAL
        ) {
            _validatePriceSlot(asset, lastTimeslot);
        }

        return true;
    }

    function _validatePriceSlot(address asset, uint256 timeslot)
        internal
        returns (bool)
    {
        // check if there is any price in timeslot
        uint256 priceCount = _priceData[asset][timeslot].length;
        if (priceCount > 0) {
            uint256[] storage dataIds = _priceData[asset][timeslot];
            uint256 maxPrice = 0;
            for (uint256 i = 0; i < dataIds.length; i++) {
                if (_priceDataList[dataIds[i]].price > maxPrice) {
                    maxPrice = _priceDataList[dataIds[i]].price;
                }
            }

            _priceFeed[asset][timeslot] = maxPrice;

            _lastValidTimeslot[asset] = timeslot;

            return true;
        } else {
            if (!_isSlashedTimeslot[asset][timeslot]) {
                // Slash everybody
                OperatorPortal.AssetInfo memory assetInfo = _portal
                    .getAssetInfo(asset);

                if (assetInfo.numOperator > 0) {
                    OperatorPortal.OperatorInfo[] memory operatorInfo = _portal
                        .getAllOperatorInfo(asset);

                    address[] memory accountList = new address[](
                        assetInfo.numOperator
                    );
                    uint256[] memory amountList = new uint256[](
                        assetInfo.numOperator
                    );

                    for (uint256 i = 0; i < assetInfo.numOperator; i++) {
                        accountList[i] = operatorInfo[i].operator;
                        amountList[i] = _calculatePenalty(
                            operatorInfo[i].stakedAmount,
                            assetInfo.totalStakedAmount
                        );
                    }

                    _portal.batchSlash(asset, accountList, amountList);
                    _isSlashedTimeslot[asset][timeslot] = true;
                }
            }
        }

        return false;
    }

    function _calculatePenalty(uint256 amount, uint256 totalAmount)
        internal
        view
        returns (uint256)
    {
        return
            (((amount * MULTIPLIER) / totalAmount) * _penaltyRate) / MULTIPLIER;
    }

    function _isValidPrice(address asset, uint256 price, uint256 timeslot)
        internal
        view
        returns (bool)
    {
        if (_firstValidTimeslot[asset] == 0) {
            return true;
        } else {
            uint256 previousSlot = timeslot - PRICE_FEED_INTERVAL;
            uint256 maxPrice = (_priceFeed[asset][previousSlot] *
                    _maxIncrementRate) /
                MULTIPLIER +
                _priceFeed[asset][previousSlot];

            if (price <= maxPrice) {
                IExchangePriceSource.Price memory rawPrice = _exchange.getPrice(
                    asset,
                    address(_baseAsset),
                    previousSlot
                );
                uint256 exchangePrice = (rawPrice.ask * MULTIPLIER) /
                    rawPrice.bid;
                uint256 exchangeGap = (exchangePrice * _maxExchangeDiffRate) /
                    MULTIPLIER;
                uint256 maxExchangePrice = exchangePrice + exchangeGap;
                uint256 minExchangePrice = exchangePrice > exchangeGap
                    ? exchangePrice - exchangeGap
                    : 0;

                if (minExchangePrice <= price && price <= maxExchangePrice) {
                    return true;
                }
            }
        }

        return false;
    }

    function _timestampToTimeslot(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return timestamp - (timestamp % PRICE_FEED_INTERVAL);
    }

    /**
     * @notice check operator can remove her stake
     * @dev true if _lastValidTimeslot is just before one timeslot
     * @param asset the address of the asset
     * @param operator the address of the operator
     * @return true if operator can remove her stake
     */
    function isStakeRemovable(address asset, address operator)
        public
        view
        returns (bool)
    {
        operator;
        uint256 previousTimeslot = _timestampToTimeslot(block.timestamp) -
            PRICE_FEED_INTERVAL;
        return _lastValidTimeslot[asset] >= previousTimeslot;
    }
}
