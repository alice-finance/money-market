pragma solidity ^0.5.11;

import "./BaseInterestCalculator.sol";

contract ZeroSavingsInterestCalculator is BaseInterestCalculator {
    function getInterestRate(
        uint256, /* totalSavings */
        uint256, /* totalBorrows */
        uint256 /* amount */
    ) public pure returns (uint256) {
        revert("CANNOT USE THIS");
    }
}
