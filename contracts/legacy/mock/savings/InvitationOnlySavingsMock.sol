pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../../savings/InvitationOnlySavings.sol";

contract InvitationOnlySavingsMock is InvitationOnlySavings {
    function setRedeemed(address account, bool redeemed) public {
        _redeemed[account] = redeemed;
    }
}
