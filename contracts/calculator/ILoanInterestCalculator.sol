pragma solidity ^0.5.11;

interface ILoanInterestCalculator {
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

    function getCollateralInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256[] calldata collateralAmounts,
        uint256 index,
        uint256 amount
    ) external pure returns (uint256);

    function getInterestShareRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 loanInterestRate,
        uint256 amount
    ) external pure returns (uint256);

    function getExpectedBalanceWithIndex(
        uint256 principal,
        uint256 fromIndex,
        uint256 toIndex
    ) external pure returns (uint256);
}
