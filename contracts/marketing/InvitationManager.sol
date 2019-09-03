pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./IMoneyMarket.sol";
import "./IInvitationManager.sol";

contract InvitationManager is IInvitationManager {
    IMoneyMarket private _market;
    uint256 private _amountOfSavingsPerInvite;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    mapping(address => address) private _inviter;
    mapping(address => bool) private _redeemed;
    mapping(address => address[]) private _redemptions;
    mapping(address => mapping(uint96 => bool)) private _nonceUsage;

    address[] private _inviterList;
    uint256 private _totalRedeemed;

    constructor(address marketAddress, uint256 amountOfSavingsPerInvite)
        public
    {
        _owner = msg.sender;
        _market = IMoneyMarket(marketAddress);
        _amountOfSavingsPerInvite = amountOfSavingsPerInvite;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "InvitationManager: not called from owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function amountOfSavingsPerInvite() public view returns (uint256) {
        return _amountOfSavingsPerInvite;
    }

    function setAmountOfSavingsPerInvite(uint256 amount) public onlyOwner {
        require(amount > 0, "InvitationManager: amount is ZERO");

        emit AmountOfSavingsPerInviteChanged(_amountOfSavingsPerInvite, amount);
        _amountOfSavingsPerInvite = amount;
    }

    function inviter(address account) public view returns (address) {
        return _inviter[account];
    }

    function invitationSlots(address account) public view returns (uint256) {
        IMoneyMarket.SavingsRecord[] memory records = _market.getSavingsRecords(
            account
        );

        if (records.length > 0) {
            uint256 totalSavings = 0;
            for (uint256 i = 0; i < records.length; i++) {
                totalSavings += records[i].balance;
            }

            return totalSavings / _amountOfSavingsPerInvite;
        }

        return 0;
    }

    function isRedeemed(address account) public view returns (bool) {
        return _redeemed[account];
    }

    function redemptions(address account)
        public
        view
        returns (address[] memory)
    {
        return _redemptions[account];
    }

    function redemptionCount(address account) public view returns (uint256) {
        return _redemptions[account].length;
    }

    function totalRedeemed() public view returns (uint256) {
        return _totalRedeemed;
    }

    function redeem(bytes32 promoCode, bytes memory signature)
        public
        returns (bool)
    {
        (address currentInviter, uint96 nonce) = _extractCode(promoCode);

        require(
            _redeemed[msg.sender] != true,
            "InvitationManager: already redeemed user"
        );

        require(
            _verifySignature(promoCode, signature),
            "InvitationManager: wrong code"
        );

        require(
            nonce <= invitationSlots(currentInviter),
            "InvitationManager: max count reached"
        );

        require(
            _nonceUsage[currentInviter][nonce] == false,
            "InvitationManager: code already used"
        );

        _inviter[msg.sender] = currentInviter;
        _redemptions[currentInviter].push(msg.sender);
        _nonceUsage[currentInviter][nonce] = true;
        _redeemed[msg.sender] = true;

        _totalRedeemed = _totalRedeemed + 1;

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
            bytes12(bytes32(uint256(promoCode) * uint256(2**(160))))
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
