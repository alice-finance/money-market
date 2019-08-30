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
        bytes3 indexed code,
        address account,
        uint256 timestamp
    );

    function codeOf(address account) external view returns (bytes3);
    function userOf(bytes3 code) external view returns (address);
    function isRegistered(address account) external view returns (bool);
    function inviter(address account) external view returns (address);
    function invitees(address account) external view returns (address[] memory);
    function inviteeCount(address account) external view returns (uint256);
    function maxInviteeCount(address account) external view returns (uint256);
    function totalRegistered() external view returns (uint256);
    function totalInviterCount() external view returns (uint256);
    function registerCode(bytes3 code) external returns (bool);
    function generateCode() external returns (bytes3);
}
