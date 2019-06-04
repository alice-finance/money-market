pragma solidity 0.5.8;

contract IInterestCalculator {
    function getInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 amount
    ) public pure returns (uint256);

    function getExpectedBalance(
        uint256 principal,
        uint256 rate,
        uint256 timeDelta
    ) public pure returns (uint256);
}
