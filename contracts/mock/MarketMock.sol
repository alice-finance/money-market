pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../MoneyMarket.sol";

contract MarketMock is MoneyMarket {
    mapping(uint256 => SavingsRecord) private _record;
    mapping(address => uint256[]) private _recordIds;

    uint256 private _totalFunds = 0;

    function setSavingsRecord(
        uint256 recordId,
        address owner,
        uint256 balance,
        uint256 timestamp
    ) public {
        _record[recordId].id = recordId;
        _record[recordId].owner = owner;
        _record[recordId].balance = balance;
        _record[recordId].initialTimestamp = timestamp;

        _recordIds[owner].push(recordId);

        _totalFunds += balance;
    }

    function totalFunds() public view returns (uint256) {
        return _totalFunds;
    }

    function getSavingsRecord(uint256 recordId)
        public
        view
        returns (SavingsRecord memory)
    {
        SavingsRecord memory record = _record[recordId];

        require(record.owner != address(0), "invalid recordId");

        return record;
    }

    function getSavingsRecords(address user)
        public
        view
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _recordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getSavingsRecord(ids[i]);
        }

        return records;
    }

    function getSavingsRecordIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _recordIds[user];
    }
}
