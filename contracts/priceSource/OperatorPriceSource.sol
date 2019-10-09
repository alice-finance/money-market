pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../staking/OperatorPortal.sol";
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

contract OperatorPriceSource is IPriceSource {
    uint256 constant PRICE_FEED_INTERVAL = 600; // 10 minutes

    OperatorPortal internal _portal;
    IERC20 internal _baseAsset;
    IExchangePriceSource internal _exchange;

    // price: token price denoted by underlying asset (DAI or ALD)
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
    // operator => timeSlot
    mapping(address => uint256) private _lastReportedSlot;
    // asset => operator => timeSlot => price
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _operatorReportedPrice;

    uint256 internal _maxIncrementRate = 10000000000000000; // 0.01;
    uint256 internal _maxExchangeDiffRate = 100000000000000000; // 0.1;

    modifier onlyOperator(address assetAddress) {
        require(
            _portal.isOperator(msg.sender, assetAddress),
            "caller is not operator"
        );
        _;
    }

    constructor(
        address portalAddress,
        address baseAssetAddress,
        address exchangeAddress
    ) public {
        _portal = OperatorPortal(portalAddress);
        _baseAsset = IERC20(baseAssetAddress);
        _exchange = IExchangePriceSource(exchangeAddress);
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
        return false;
    }

    function _timestampToTimeslot(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return timestamp - (timestamp % PRICE_FEED_INTERVAL);
    }
}
