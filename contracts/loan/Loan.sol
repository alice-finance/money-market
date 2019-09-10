pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../savings/InvitationOnlySavings.sol";
import "./PriceManager.sol";
import "./ILoan.sol";

contract Loan is InvitationOnlySavings, PriceManager, ILoan {
    function _liquidate() internal;
    function applyForLiquidation() public;
    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) public returns (uint256);
    function repay(uint256 recordId, uint256 amount) public returns (bool);
    function supplyCollateral(uint256 recordId, uint256 amount)
        public
        returns (bool);
    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount
    ) public returns (bool);
}
