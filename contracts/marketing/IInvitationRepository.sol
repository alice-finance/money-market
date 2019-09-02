pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract IInvitationRepository {
    event InvitationCodeGenerated(
        address indexed account,
        bytes3 code,
        uint256 timestamp
    );
    event InvitationCodeUsed(
        address indexed inviter,
        bytes32 indexed code,
        address account,
        uint256 timestamp
    );
    event AmountPerInviteChanged(uint256 from, uint256 to);

    function isRegistered(address account) external view returns (bool);
    function inviter(address account) external view returns (address);
    function invitees(address account) external view returns (address[] memory);
    function inviteeCount(address account) external view returns (uint256);
    function maxInviteeCount(address account) external view returns (uint256);
    function totalRegistered() external view returns (uint256);
    function redeem(bytes32 promoCode, bytes calldata signature)
        external
        returns (bool);
}
