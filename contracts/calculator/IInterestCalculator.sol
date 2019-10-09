pragma solidity ^0.5.11;

interface IInterestCalculator {
    function getInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 amount
    ) external pure returns (uint256);

    function getExpectedBalance(
        uint256 principal,
        uint256 rate,
        uint256 timeDelta
    ) external pure returns (uint256);
}
