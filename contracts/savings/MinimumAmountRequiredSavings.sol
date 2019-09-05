pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./Savings.sol";

contract MinimumAmountRequiredSavings is Savings {
    uint256 internal _minimumSavingsAmount;

    event MinimumSavingsAmountChanged(uint256 from, uint256 to);

    function minimumSavingsAmount()
        public
        view
        delegated
        initialized
        returns (uint256)
    {
        return _minimumSavingsAmount;
    }

    function setMinimumSavingsAmount(uint256 amount)
        public
        delegated
        initialized
        onlyOwner
    {
        emit MinimumSavingsAmountChanged(_minimumSavingsAmount, amount);
        _minimumSavingsAmount = amount;
    }
}
