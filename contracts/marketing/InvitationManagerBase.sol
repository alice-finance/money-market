pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../savings/DelegatedSavingsBase.sol";
import "./IInvitationManager.sol";

contract InvitationManagerBase is DelegatedSavingsBase, IInvitationManager {
    uint256 internal _amountOfSavingsPerInvite;

    mapping(address => address) internal _inviter;
    mapping(address => bool) internal _redeemed;
    mapping(address => address[]) internal _redemptions;
    mapping(address => mapping(uint96 => bool)) internal _nonceUsage;

    address[] internal _inviterList;
    uint256 internal _totalRedeemed;
}
