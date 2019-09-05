pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./InvitationOnlySavingsBase.sol";

contract InvitationOnlySavings is InvitationOnlySavingsBase {
    function initialize(
        IInterestCalculator newCalculator,
        uint256 newMinimumSavingsAmount
    ) public {
        _initialize(1);

        setSavingsInterestCalculator(newCalculator);
        setMinimumSavingsAmount(newMinimumSavingsAmount);
    }
}
