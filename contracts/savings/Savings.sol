pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./SavingsBase.sol";
import "../ownership/TrustlessOwner.sol";

contract Savings is SavingsBase {
    function deposit(uint256 amount) public returns (uint256) {
        uint256 result = _deposit(msg.sender, amount);
        TrustlessOwner(_owner).executePendingTransactions();
        return result;
    }

    function withdraw(uint256 recordId, uint256 amount) public returns (bool) {
        bool result = _withdraw(msg.sender, recordId, amount);
        TrustlessOwner(_owner).executePendingTransactions();
        return result;
    }

    function getSavingsRecordIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _userSavingsRecordIds[user];
    }

    function getSavingsRecords(address user)
        public
        view
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            records[i] = getSavingsRecord(ids[i]);
        }

        return records;
    }

    function getSavingsRecord(uint256 recordId)
        public
        view
        returns (SavingsRecord memory)
    {
        require(recordId < _savingsRecords.length, "invalid recordId");
        SavingsRecord memory record = _savingsRecords[recordId];

        record.balance = _getCurrentSavingsBalance(record);
        record.lastTimestamp = block.timestamp;

        return record;
    }

    function getRawSavingsRecords(address user)
        public
        view
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            records[i] = _savingsRecords[ids[i]];
        }

        return records;
    }

    function getRawSavingsRecord(uint256 recordId)
        public
        view
        returns (SavingsRecord memory)
    {
        require(recordId < _savingsRecords.length, "invalid recordId");
        return _savingsRecords[recordId];
    }
}
