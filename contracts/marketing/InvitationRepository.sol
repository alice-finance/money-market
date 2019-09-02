pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./IMoneyMarket.sol";
import "./IInvitationRepository.sol";

// TODO: add ability to set length of invitation code
// TODO: change type of code from bytes3 to bytes
// TODO: Change word "invite" to "redeem" on methods
// TODO: change "address" from function arguments into "code"
contract InvitationRepository is IInvitationRepository {
    IMoneyMarket private _market;
    uint256 private _amountPerInvitee;

    // inviter => code
    mapping(address => bytes3) private _codes;
    // code => inviter
    mapping(bytes3 => address) private _reverseCodes;
    // invitee = registered
    mapping(address => bool) private _registered;
    // invitee => inviter
    mapping(address => address) private _inviter;
    // inviter => invitees
    mapping(address => address[]) private _invitees;

    address[] private _inviterList;
    uint256 private _totalRegistered;

    constructor(address marketAddress, uint256 amountPerInvitee) public {
        _market = IMoneyMarket(marketAddress);
        _amountPerInvitee = amountPerInvitee;
    }

    //    function codeOf(address account) public view returns (bytes3) {
    //        return _codes[account];
    //    }

    function userOf(bytes3 code) public view returns (address) {
        return _reverseCodes[code];
    }

    function isRegistered(address account) public view returns (bool) {
        return _registered[account];
    }

    function inviter(address account) public view returns (address) {
        return _inviter[account];
    }

    function invitees(address account) public view returns (address[] memory) {
        return _invitees[account];
    }

    function inviteeCount(address account) public view returns (uint256) {
        return _invitees[account].length;
    }

    function maxInviteeCount(address account) public view returns (uint256) {
        IMoneyMarket.SavingsRecord[] memory records = _market.getSavingsRecords(
            account
        );

        if (records.length > 0) {
            uint256 totalSavings = 0;
            for (uint256 i = 0; i < records.length; i++) {
                totalSavings += records[i].balance;
            }

            return totalSavings / _amountPerInvitee;
        }

        return 0;
    }

    function totalRegistered() public view returns (uint256) {
        return _totalRegistered;
    }

    function totalInviterCount() public view returns (uint256) {
        return _inviterList.length;
    }

    // TODO:
    function redeem(bytes32 promoCode, bytes memory signature)
        public
        returns (bool)
    {
        require(
            _registered[msg.sender] != true,
            "InviteCode: already registered"
        );

        //        address currentInviter = bytes20(promoCode);
        //        uint96 index = bytes12(promoCode << 20);
        //        (uint8 v, bytes32 r, bytes32 s) = _extractSignature(signature);
        //        require(ecrecover(promoCode, v, r, s) == currentInviter);
        //
        //        require(
        //            index < maxInviteeCount(currentInviter),
        //            "InviteCode: this code cannot be used"
        //        );
        //
        //        _inviter[msg.sender] = currentInviter;
        //        _invitees[currentInviter].push(msg.sender);
        //        _registered[msg.sender] = true;
        //
        //        _totalRegistered = _totalRegistered + 1;

        return true;
    }

    function _extractSignature(bytes memory signature)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return (v, r, s);
    }

    function _generateCode(address account, uint256 pos)
        private
        pure
        returns (bytes3)
    {
        return bytes3(bytes20(uint160(account) * uint160(2**(4 * pos))));
        // return bytes3(bytes20(account) << (4 * pos));
    }
}
