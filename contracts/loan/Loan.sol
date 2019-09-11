pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../savings/InvitationOnlySavings.sol";
import "./PriceManager.sol";
import "./ILoan.sol";

contract Loan is InvitationOnlySavings, PriceManager, ILoan {
    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) public returns (uint256) {
        uint256 result = _borrow(
            msg.sender,
            amount,
            collateral,
            collateralAmount
        );
        validatePrice();
        return result;
    }

    function repay(uint256 recordId, uint256 amount) public returns (bool) {
        validatePrice();
        return false;
    }

    function supplyCollateral(uint256 recordId, uint256 amount)
        public
        returns (bool)
    {
        validatePrice();
        return false;
    }

    // @dev liquidate function is not implemented - liquidation is operators only
    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount
    ) public returns (bool) {
        revert("NOT AVAILABLE");
    }

    function applyForLiquidation(uint256 recordId) public returns (bool) {
        return false;
    }

    function _borrow(
        address user,
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) internal returns (bool) {
        return false;
    }

    function _liquidate() internal returns (bool) {
        return false;
    }
}
