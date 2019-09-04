pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./InvitationOnlySavingsBase.sol";

contract InvitationOnlySavings is InvitationOnlySavingsBase {
    function initialize(uint256 minimumSavingsAmount) public {
        require(_initialize(1));

        setMinimumSavingsAmount(minimumSavingsAmount);
    }
}
