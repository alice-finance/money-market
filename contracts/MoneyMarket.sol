pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./savings/Savings.sol";

contract MoneyMarket is Savings {
    constructor(address assetAddress, address savingsInterestCalculatorAddress)
        public
    {
        _owner = msg.sender;
        _guardCounter = 1;

        _totalBorrows = 0;
        _totalFunds = 0;
        _earnedInterests = 0;
        _paidInterests = 0;

        _asset = IERC20(assetAddress);
        _savingsInterestCalculator = IInterestCalculator(
            savingsInterestCalculatorAddress
        );
    }
}
