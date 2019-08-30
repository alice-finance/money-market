pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract InvitationRepositoryMock {
    mapping(address => bool) private _registered;

    function codeOf(address account) public view returns (bytes3) {
        revert("not implemented");
    }

    function userOf(bytes3 code) public view returns (address) {
        revert("not implemented");
    }

    function isRegistered(address account) public view returns (bool) {
        return _registered[account];
    }

    function setRegistered(address account, bool registered) public {
        _registered[account] = registered;
    }

    function inviter(address account) public view returns (address) {
        revert("not implemented");
    }

    function invitees(address account) public view returns (address[] memory) {
        revert("not implemented");
    }

    function inviteeCount(address account) public view returns (uint256) {
        revert("not implemented");
    }

    function maxInviteeCount(address account) public view returns (uint256) {
        revert("not implemented");
    }

    function totalRegistered() public view returns (uint256) {
        revert("not implemented");
    }

    function totalInviterCount() public view returns (uint256) {
        revert("not implemented");
    }

    function registerCode(bytes3 code) public returns (bool) {
        revert("not implemented");
    }

    function generateCode() public returns (bytes3) {
        revert("not implemented");
    }
}
