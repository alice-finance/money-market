pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./IMoneyMarket.sol";
import "./IInvitationRepository.sol";

contract InvitationRepository is IInvitationRepository {
    IMoneyMarket private _market;
    uint256 private _amountPerInvite;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // code => inviter
    mapping(bytes3 => address) private _reverseCodes;
    // invitee = registered
    mapping(address => bool) private _registered;
    // invitee => inviter
    mapping(address => address) private _inviter;
    // inviter => invitees
    mapping(address => address[]) private _invitees;
    // inviter => nonce => used
    mapping(address => mapping(uint96 => bool)) private _nonceUsage;

    address[] private _inviterList;
    uint256 private _totalRegistered;

    constructor(address marketAddress, uint256 amountPerInvite) public {
        _owner = msg.sender;
        _market = IMoneyMarket(marketAddress);
        _amountPerInvite = amountPerInvite;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "InvitationRepository: not called from owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function amountPerInvite() public view returns (uint256) {
        return _amountPerInvite;
    }

    function setAmountPerInvite(uint256 amount) public onlyOwner {
        require(amount > 0, "InvitationRepository: amount is ZERO");

        emit AmountPerInviteChanged(_amountPerInvite, amount);
        _amountPerInvite = amount;
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

            return totalSavings / _amountPerInvite;
        }

        return 0;
    }

    function totalRegistered() public view returns (uint256) {
        return _totalRegistered;
    }

    function redeem(bytes32 promoCode, bytes memory signature)
        public
        returns (bool)
    {
        (address currentInviter, uint96 nonce) = _extractCode(promoCode);

        require(
            _registered[msg.sender] != true,
            "InvitationRepository: already registered user"
        );

        require(
            _verifySignature(promoCode, signature),
            "InvitationRepository: wrong code"
        );

        require(
            nonce <= maxInviteeCount(currentInviter),
            "InvitationRepository: max count reached"
        );

        require(
            _nonceUsage[currentInviter][nonce] == false,
            "InvitationRepository: code already used"
        );

        _inviter[msg.sender] = currentInviter;
        _invitees[currentInviter].push(msg.sender);
        _nonceUsage[currentInviter][nonce] = true;
        _registered[msg.sender] = true;

        _totalRegistered = _totalRegistered + 1;

        emit InvitationCodeUsed(
            currentInviter,
            promoCode,
            msg.sender,
            block.timestamp
        );

        return true;
    }

    function _extractCode(bytes32 promoCode)
        internal
        pure
        returns (address, uint96)
    {
        address currentInviter = address(bytes20(promoCode));
        uint96 nonce = uint96(
            bytes12(bytes32(uint256(promoCode) * uint256(2 ** (160))))
        );

        return (currentInviter, nonce);
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

    function _verifySignature(bytes32 promoCode, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        (address currentInviter, ) = _extractCode(promoCode);
        bytes32 hash = keccak256(abi.encode(promoCode));
        bytes32 hash2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        (uint8 v, bytes32 r, bytes32 s) = _extractSignature(signature);

        return ecrecover(hash2, v, r, s) == currentInviter;
    }
}
