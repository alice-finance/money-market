pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

interface IInvitationManager {
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
    event AmountOfSavingsPerInviteChanged(uint256 from, uint256 to);

    function inviter(address account) external view returns (address);
    function invitationSlots(address account) external view returns (uint256);
    function isRedeemed(address account) external view returns (bool);
    function redeemers(address account)
        external
        view
        returns (address[] memory);
    function redeemerCount(address account) external view returns (uint256);
    function totalRedeemed() external view returns (uint256);
    function redeem(bytes calldata redeemData) external returns (bool);
}
