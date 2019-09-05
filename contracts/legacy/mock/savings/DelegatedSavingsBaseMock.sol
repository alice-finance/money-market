pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../../savings/DelegatedSavingsBase.sol";

contract DelegatedSavingsBaseMock is DelegatedSavingsBase {
    function initialize(
        IInterestCalculator newCalculator,
        uint256 newMinimumSavingsAmount
    ) public {
        _initialize(1);

        setSavingsInterestCalculator(newCalculator);
        setMinimumSavingsAmount(newMinimumSavingsAmount);
    }
}
