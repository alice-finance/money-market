pragma solidity ^0.5.11;

import "./IInterestCalculator.sol";

contract ILoanInterestCalculator is IInterestCalculator {
    function getCollateralInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256[] memory collateralAmounts,
        uint256 index,
        uint256 amount
    ) public pure returns (uint256);
}
