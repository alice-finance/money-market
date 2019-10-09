pragma solidity ^0.5.11;

import "./BaseInterestCalculator.sol";

contract SavingsInterestCalculatorV2 is BaseInterestCalculator {
    uint256 constant A = 351460000000000;
    uint256 constant C = 0;
    function getInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 r = (totalBorrows * A) / totalSavings;

        return r;
    }
}
