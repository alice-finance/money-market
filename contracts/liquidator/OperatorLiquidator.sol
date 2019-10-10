pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../Ownable.sol";
import "../operator/IDelegator.sol";
import "../loan/ILoan.sol";
import "../operator/OperatorPortal.sol";

contract OperatorLiquidator is IDelegator, Ownable {
    ILoan private _loan;
    OperatorPortal private _portal;
    IERC20 private _baseAsset;

    uint256 private _minimumCollateralRate = 1500000000000000000;
    uint256 private _dangerCollateralRate = 1600000000000000000;
    // asset => operator => amount
    mapping(address => mapping(address => uint256)) private _collateralAmount;

    modifier onlyOperator(address asset) {
        require(
            _portal.isOperator(msg.sender, asset),
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
                _minimumCollateralRate + 1,
                _dangerCollateralRate,
                new bytes(0)
            );
    }

    function getLoansOnDefault(address asset)
        public
        view
        returns (ILoan.LoanRecord[] memory)
    {
        return
            _loan.getActiveLoanRecordsByCollateralWithData(
                asset,
                0,
                _minimumCollateralRate,
                new bytes(0)
            );
    }

    function liquidateAll(address asset) public onlyOperator(asset) {
        ILoan.LoanRecord[] memory loans = getLoansOnDefault(asset);
        OperatorPortal.AssetInfo memory assetInfo = _portal.getAssetInfo(asset);

        if (assetInfo.numOperator > 0) {
            OperatorPortal.OperatorInfo[] memory operatorInfo = _portal
                .getAllOperatorInfo(asset);

            for (uint256 i = 0; i < loans.length; i++) {
                _liquidate(loans[i], assetInfo, operatorInfo);
            }
        }
    }

    function _liquidate(
        ILoan.LoanRecord memory loan,
        OperatorPortal.AssetInfo memory assetInfo,
        OperatorPortal.OperatorInfo[] memory operatorInfo
    ) internal {
        // Pre-calculate
        uint256[] memory participatorIds = new uint256[](assetInfo.numOperator);
        uint256 participatorLength = assetInfo.numOperator;
        uint256 participatorStake = assetInfo.totalStakedAmount;
        uint256[] memory penaltyIds = new uint256[](assetInfo.numOperator);
        uint256 penaltyLength = 0;
        uint256 totalBorrows = _loan.totalBorrowByCollateral(assetInfo.asset);

        for (uint256 i = 0; i < assetInfo.numOperator; i++) {
            participatorIds[i] = i;
        }

        for (uint256 i = 0; i < participatorLength; i++) {
            OperatorPortal.OperatorInfo memory info = operatorInfo[participatorIds[i]];

            uint256 amount = (loan.balance * info.stakedAmount) /
                participatorStake;

            if (
                _baseAsset.allowance(info.operator, address(this)) >= amount &&
                _baseAsset.balanceOf(info.operator) >= amount
            ) {
                participatorLength += 1;
            } else {
                penaltyIds[penaltyLength] = participatorIds[i];
                penaltyLength += 1;
                participatorIds[i] = participatorIds[participatorLength - 1];
                participatorLength -= 1;
                participatorStake -= info.stakedAmount;
            }
        }

        // Liquidate
        if (participatorLength > 0) {
            uint256 balance = 0;
            for (uint256 i = 0; i < participatorLength; i++) {
                OperatorPortal.OperatorInfo memory info = operatorInfo[participatorIds[i]];

                uint256 baseAssetAmount = (loan.balance * info.stakedAmount) /
                    participatorStake;
                balance += baseAssetAmount;
                uint256 collateralAmount = (loan.collateralAmount *
                        info.stakedAmount) /
                    participatorStake;
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
                loan.id,
                balance,
                loan.collateralAmount,
                new bytes(0)
            );
        }

        if (penaltyLength > 0) {
            address[] memory accountList = new address[](penaltyLength);
            uint256[] memory amountList = new uint256[](penaltyLength);

            // slash
            for (uint256 i = 0; i < penaltyLength; i++) {
                OperatorPortal.OperatorInfo memory info = operatorInfo[penaltyIds[i]];

                uint256 penalty = (info.stakedAmount *
                        loan.balance *
                        MULTIPLIER) /
                    assetInfo.totalStakedAmount /
                    totalBorrows;

                accountList[i] = info.operator;
                amountList[i] = penalty;
            }

            _portal.batchSlash(assetInfo.asset, accountList, amountList);
        }
    }
}
