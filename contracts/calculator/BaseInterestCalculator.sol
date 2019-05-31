pragma solidity 0.5.8;

import "./IInterestCalculator.sol";

contract BaseInterestCalculator is IInterestCalculator {
    uint256 public constant MULTIPLIER = 10 ** 18;

    function getInterestRate(
        uint256, /* totalSavings */
        uint256, /* totalBorrows */
        uint256 /* amount */
    ) public pure returns (uint256) {
        revert("not implemented");
    }

    function getCurrentBalance(
        uint256 principal,
        uint256 rate,
        uint256 timeDelta
    ) public pure returns (uint256) {
        require(rate > 0, "invalid rate");

        uint256 terms = timeDelta / 86400;

        if (principal == 0) {
            return 0;
        }

        if (terms == 0) {
            return principal;
        }

        return _getBalance(principal, rate, terms);
    }

    function _getBalance(uint256 principal, uint256 rate, uint256 terms)
        internal
        pure
        returns (uint256)
    {
        uint256 balance = principal;

        for (uint i = 0; i < terms; i++) {
            balance = balance * (MULTIPLIER + rate) / MULTIPLIER;
        }

        return balance;
    }
}
