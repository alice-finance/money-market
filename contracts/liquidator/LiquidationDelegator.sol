pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../Ownable.sol";
import "../operator/IDelegator.sol";
import "../loan/ILoan.sol";
import "../operator/OperatorPortal.sol";
import "../timeslot/Timeslot.sol";
import "../priceSource/IPriceSource.sol";

contract LiquidationDelegator is IDelegator, Constants, Timeslot, Ownable {
    ILoan private _loan;
    OperatorPortal private _portal;
    IPriceSource private _priceSource;
    IERC20 private _baseAsset;

    uint256 private _defaultCollateralRate = 1490000000000000000; // 1.49
    uint256 private _minimumCollateralRate = 1500000000000000000; // 1.5
    uint256 private _dangerCollateralRate = 1600000000000000000; // 1.6
    uint256 internal _timeslotPenaltyRate = 10000000000000000; // 0.01;

    // asset => operator => amount
    mapping(address => mapping(address => uint256)) private _collateralAmount;
    // asset => timeslot
    mapping(address => uint256) private _lastCheckedTimeslot;

    event OperatorPortalChanged(address indexed from, address indexed to);
    event BaseAssetChanged(address indexed from, address indexed to);
    event PriceSourceChanged(address indexed from, address indexed to);
    event LoanChanged(address indexed from, address indexed to);

    constructor(
        address ownerAddress,
        address portalAddress,
        address baseAssetAddress,
        address priceSourceAddress,
        address loanAddress
    ) public {
        _owner = ownerAddress;
        _portal = OperatorPortal(portalAddress);
        _baseAsset = IERC20(baseAssetAddress);
        _priceSource = IPriceSource(priceSourceAddress);
        _loan = ILoan(loanAddress);
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

    function priceSource() public view returns (IPriceSource) {
        return _priceSource;
    }

    function setPriceSource(IPriceSource newSource) public onlyOwner {
        require(address(newSource) != address(0));

        emit PriceSourceChanged(address(_priceSource), address(newSource));

        _priceSource = newSource;
    }

    function loan() public view returns (ILoan) {
        return _loan;
    }

    function setLoan(ILoan newLoan) public onlyOwner {
        require(address(newLoan) != address(0));

        emit LoanChanged(address(_loan), address(newLoan));

        _loan = newLoan;
    }

    modifier onlyOperator(address asset) {
        require(
            _portal.isOperator(asset, msg.sender),
            "caller is not operator"
        );
        _;
    }

    function getLoansInDanger(address asset)
        public
        view
        returns (ILoan.LoanRecord[] memory)
    {
        return
            _loan.getActiveLoanRecordsByCollateralWithData(
                asset,
                _defaultCollateralRate + 1,
                _dangerCollateralRate,
                new bytes(0)
            );
    }

    event LogAddress(string msg, address addr);
    event LogBytes(string msg, bytes data);

    function test(address asset)
        public
    //        returns (ILoan.LoanRecord[] memory)
    {
        uint8 dataType = 1;
        bytes memory data = abi.encodePacked(dataType, asset);

        emit LogAddress("address", asset);
        emit LogBytes("data", data);

        _loan.getLoanRecordsOnDefaultWithData(data);
        //        return _loan.getLoanRecordsOnDefaultWithData(data);
    }

    function getLoansOnDefault(address asset)
        public
        view
        returns (ILoan.LoanRecord[] memory)
    {
        uint8 dataType = 1;
        bytes memory data = abi.encodePacked(dataType, asset);

        return _loan.getLoanRecordsOnDefaultWithData(data);
    }

    function liquidateAll(address asset)
        public
        onlyOperator(asset)
        returns (bool)
    {
        uint256 current = timestampToTimeslot(block.timestamp);
        uint256 previous = previousTimeslot(current);

        if (_lastCheckedTimeslot[asset] < previous) {
            if (
                _lastCheckedTimeslot[asset] > 0 &&
                previous - _lastCheckedTimeslot[asset] > PRICE_FEED_INTERVAL
            ) {
                _penalizeTimeslots(
                    asset,
                    _lastCheckedTimeslot[asset],
                    previous
                );
            }

            uint256 price = _priceSource.getLastPrice(asset);
            // uint256 price = _priceSource.getPrice(asset, previous);

            // if price posted
            if (price > 0) {
                _lastCheckedTimeslot[asset] = previous;
                ILoan.LoanRecord[] memory loans = getLoansOnDefault(asset);
                OperatorPortal.AssetInfo memory assetInfo = _portal
                    .getAssetInfo(asset);

                if (assetInfo.numOperator > 0) {
                    OperatorPortal.OperatorInfo[] memory operatorInfo = _portal
                        .getAllOperatorInfo(asset);

                    for (uint256 i = 0; i < loans.length; i++) {
                        _liquidate(loans[i], assetInfo, operatorInfo, price);
                    }
                }

                return true;
            }
        }

        return false;
    }

    struct LiquidateParams {
        uint256 loanValue;
        uint256 participatorLength;
        uint256 participatorStake;
        uint256 penaltyLength;
        uint256 totalBorrows;
    }

    function _liquidate(
        ILoan.LoanRecord memory targetLoan,
        OperatorPortal.AssetInfo memory assetInfo,
        OperatorPortal.OperatorInfo[] memory operatorInfo,
        uint256 price
    ) internal {
        // Pre-calculate
        LiquidateParams memory params = LiquidateParams(0, 0, 0, 0, 0);
        params.loanValue = (targetLoan.collateralAmount * price) / MULTIPLIER;
        uint256[] memory participatorIds = new uint256[](assetInfo.numOperator);
        params.participatorLength = 0;
        params.participatorStake = assetInfo.totalStakedAmount;
        uint256[] memory penaltyIds = new uint256[](assetInfo.numOperator);
        params.penaltyLength = 0;
        params.totalBorrows = _loan.totalBorrowsByCollateral(assetInfo.asset);

        for (uint256 i = 0; i < assetInfo.numOperator; i++) {
            OperatorPortal.OperatorInfo memory info = operatorInfo[i];

            uint256 amount = (params.loanValue * info.stakedAmount) /
                params.participatorStake;

            if (
                _baseAsset.allowance(info.operator, address(this)) >= amount &&
                _baseAsset.balanceOf(info.operator) >= amount
            ) {
                if (targetLoan.owner != info.operator) {
                    participatorIds[params.participatorLength] = i;
                    params.participatorLength += 1;
                    params.participatorStake += info.stakedAmount;
                }
            } else {
                penaltyIds[params.penaltyLength] = i;
                params.penaltyLength += 1;
            }

        }

        // Liquidate
        if (params.participatorLength > 0) {
            uint256 balance = 0;
            for (uint256 i = 0; i < params.participatorLength; i++) {
                OperatorPortal.OperatorInfo memory info = operatorInfo[participatorIds[i]];
                uint256 baseAssetAmount = (params.loanValue *
                        info.stakedAmount) /
                    params.participatorStake;
                balance += baseAssetAmount;
                uint256 collateralAmount = (targetLoan.collateralAmount *
                        info.stakedAmount) /
                    params.participatorStake;
                _collateralAmount[assetInfo.asset][info
                    .operator] += collateralAmount;
                require(
                    _baseAsset.transferFrom(
                        info.operator,
                        address(this),
                        baseAssetAmount
                    )
                );
            }

            _loan.liquidate(
                targetLoan.id,
                balance,
                targetLoan.collateralAmount,
                new bytes(0)
            );

        }

        // penalize
        if (params.penaltyLength > 0) {
            address[] memory accountList = new address[](params.penaltyLength);
            uint256[] memory amountList = new uint256[](params.penaltyLength);

            // slash
            for (uint256 i = 0; i < params.penaltyLength; i++) {
                OperatorPortal.OperatorInfo memory info = operatorInfo[penaltyIds[i]];

                uint256 penalty = (info.stakedAmount *
                        params.loanValue *
                        MULTIPLIER) /
                    assetInfo.totalStakedAmount /
                    params.totalBorrows;

                accountList[i] = info.operator;
                amountList[i] = penalty;
            }

            _portal.batchSlash(assetInfo.asset, accountList, amountList);
        }

    }

    function _penalizeTimeslots(
        address asset,
        uint256 fromTimeslot,
        uint256 toTimeslot
    ) internal {
        for (
            uint256 lastTimeslot = fromTimeslot;
            lastTimeslot < toTimeslot;
            lastTimeslot += PRICE_FEED_INTERVAL
        ) {
            _penalizeTimeslot(asset, lastTimeslot);
        }
    }

    function _penalizeTimeslot(address asset, uint256 timeslot) internal {
        OperatorPortal.AssetInfo memory assetInfo = _portal.getAssetInfo(asset);
        _lastCheckedTimeslot[asset] = timeslot;

        if (assetInfo.numOperator > 0) {
            OperatorPortal.OperatorInfo[] memory operatorInfo = _portal
                .getAllOperatorInfo(asset);

            address[] memory accountList = new address[](assetInfo.numOperator);
            uint256[] memory amountList = new uint256[](assetInfo.numOperator);

            for (uint256 i = 0; i < assetInfo.numOperator; i++) {
                accountList[i] = operatorInfo[i].operator;
                amountList[i] = _calculateTimeslotPenalty(
                    operatorInfo[i].stakedAmount,
                    assetInfo.totalStakedAmount
                );
            }

            _portal.batchSlash(asset, accountList, amountList);
        }
    }

    function _calculateTimeslotPenalty(uint256 amount, uint256 totalAmount)
        internal
        view
        returns (uint256)
    {
        return (amount * _timeslotPenaltyRate) / totalAmount;
    }

    function isDelegator() public view returns (bool) {
        return true;
    }

    /**
     * @notice check operator can remove her stake
     * @dev true if _lastCheckedTimeslot is just before one timeslot
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
        uint256 previousTimeslot = previousTimeslot(
            timestampToTimeslot(block.timestamp)
        );
        return _lastCheckedTimeslot[asset] >= previousTimeslot;
    }
}
