pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../marketing/IInvitationManager.sol";

contract InvitationManagerMock is IInvitationManager {
    mapping(address => bool) private _redeemed;

    function isRedeemed(address account) public view returns (bool) {
        return _redeemed[account];
    }

    function setRedeemed(address account, bool redeemed) public {
        _redeemed[account] = redeemed;
    }

    function inviter(
        address /* account */
    ) public view returns (address) {
        revert("not implemented");
    }

    function invitationSlots(
        address /* account */
    ) public view returns (uint256) {
        revert("not implemented");
    }

    function redemptions(
        address /* account */
    ) public view returns (address[] memory) {
        revert("not implemented");
    }

    function redemptionCount(
        address /* account */
    ) public view returns (uint256) {
        revert("not implemented");
    }

    function totalRedeemed() public view returns (uint256) {
        revert("not implemented");
    }

    function redeem(
        bytes32, /* promoCode */
        bytes memory /* signature */
    ) public returns (bool) {
        revert("not implemented");
    }
}
