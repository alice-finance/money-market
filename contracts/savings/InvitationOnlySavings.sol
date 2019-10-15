pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "./MinimumAmountRequiredSavings.sol";
import "../invitation/IInvitationManager.sol";

contract InvitationOnlySavings is
    MinimumAmountRequiredSavings,
    IInvitationManager
{
    uint256 internal _amountOfSavingsPerInvite;

    mapping(address => address) internal _inviter;
    mapping(address => bool) internal _redeemed;
    mapping(address => address[]) internal _redeemers;
    mapping(address => mapping(uint96 => bool)) internal _nonceUsage;

    address[] internal _inviterList;
    uint256 internal _totalRedeemed;

    function amountOfSavingsPerInvite() public view returns (uint256) {
        return _amountOfSavingsPerInvite;
    }

    function setAmountOfSavingsPerInvite(uint256 amount) public onlyOwner {
        require(amount > 0, "amount is ZERO");

        emit AmountOfSavingsPerInviteChanged(_amountOfSavingsPerInvite, amount);
        _amountOfSavingsPerInvite = amount;
    }

    function inviter(address account) public view returns (address) {
        return _inviter[account];
    }

    function invitationSlots(address account) public view returns (uint256) {
        SavingsRecord[] memory records = getSavingsRecordsWithData(
            account,
            new bytes(0)
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

    function redeemers(address account) public view returns (address[] memory) {
        return _redeemers[account];
    }

    function redeemerCount(address account) public view returns (uint256) {
        return _redeemers[account].length;
    }

    function totalRedeemed() public view returns (uint256) {
        return _totalRedeemed;
    }

    function depositWithData(uint256 amount, bytes memory data)
        public
        returns (uint256)
    {
        (uint8 dataType, bytes memory extractedData) = _extractData(data);
        if (dataType == 1) {
            redeem(extractedData);
        }

        if (!isRedeemed(msg.sender)) {
            revert("not redeemed");
        }

        require(amount >= _minimumSavingsAmount, "at least minimum amount");

        return _deposit(msg.sender, amount, data);
    }

    function redeem(bytes memory redeemData) public returns (bool) {
        (bytes32 promoCode, bytes memory signature) = _extractRedeemData(
            redeemData
        );
        (address currentInviter, uint96 nonce) = _extractPromoCode(promoCode);

        require(_redeemed[msg.sender] != true, "already redeemed");

        require(_verifySignature(promoCode, signature), "wrong code");

        require(nonce <= invitationSlots(currentInviter), "max redeem count");

        require(_nonceUsage[currentInviter][nonce] == false, "used code");

        _inviter[msg.sender] = currentInviter;
        _redeemers[currentInviter].push(msg.sender);
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

    function _extractRedeemData(bytes memory data)
        internal
        pure
        returns (bytes32, bytes memory)
    {
        require(data.length >= 32, "invalid data");
        uint256 signatureLength = data.length - 32;

        bytes32 promoCode;
        bytes memory signature = new bytes(signatureLength);

        assembly {
            promoCode := mload(add(data, 32))
        }

        for (uint256 i = 32; i < data.length; i++) {
            signature[i - 32] = data[i];
        }

        return (promoCode, signature);
    }

    function _extractPromoCode(bytes32 promoCode)
        internal
        pure
        returns (address, uint96)
    {
        address currentInviter = address(bytes20(promoCode));
        uint96 nonce = uint96(
            bytes12(bytes32(uint256(promoCode) * uint256(2**(160))))
        );

        require(currentInviter != address(0), "invalid inviter");
        require(nonce > 0, "invalid nonce");

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
        (address currentInviter, ) = _extractPromoCode(promoCode);
        bytes32 hash = keccak256(abi.encode(promoCode));
        bytes32 hash2 = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        (uint8 v, bytes32 r, bytes32 s) = _extractSignature(signature);

        return ecrecover(hash2, v, r, s) == currentInviter;
    }
}
