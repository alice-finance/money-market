pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../base/Fund.sol";
import "./SavingsData.sol";
import "../ReentrancyGuard.sol";

contract Savings is Fund, SavingsData, ReentrancyGuard {
    IInterestCalculator internal _newSavingsCalculator;

    function savingsCalculatorWithData(bytes memory data)
        public
        view
        delegated
        initialized
        returns (IInterestCalculator)
    {
        return _newSavingsCalculator;
    }

    function setSavingsCalculatorWithData(
        IInterestCalculator calculator,
        bytes memory data
    ) public delegated initialized onlyOwner {
        require(address(calculator) != address(0), "ZERO address");

        emit SavingsCalculatorChanged(
            address(_newSavingsCalculator),
            address(calculator)
        );
        _newSavingsCalculator = calculator;
    }

    function depositWithData(uint256 amount, bytes memory data)
        public
        delegated
        initialized
        returns (uint256)
    {
        return _deposit(msg.sender, amount, data);
    }

    function withdrawWithData(
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) public delegated initialized returns (bool) {
        return _withdraw(msg.sender, recordId, amount, data);
    }

    function getSavingsRecordIdsWithData(address user, bytes memory data)
        public
        view
        delegated
        initialized
        returns (uint256[] memory)
    {
        return _userSavingsRecordIds[user];
    }

    function getSavingsRecordsWithData(address user, bytes memory data)
        public
        view
        delegated
        initialized
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getSavingsRecordWithData(ids[i], data);
        }

        return records;
    }

    function getSavingsRecordWithData(uint256 recordId, bytes memory data)
        public
        view
        delegated
        initialized
        returns (SavingsRecord memory)
    {
        require(recordId < _savingsRecords.length, "invalid recordId");
        SavingsRecord memory record = _savingsRecords[recordId];

        record.balance = _getCurrentSavingsBalance(record);
        record.lastTimestamp = block.timestamp;

        return record;
    }

    function getRawSavingsRecordsWithData(address user, bytes memory data)
        public
        view
        delegated
        initialized
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = _savingsRecords[ids[i]];
        }

        return records;
    }

    function getRawSavingsRecordWithData(uint256 recordId, bytes memory data)
        public
        view
        delegated
        initialized
        returns (SavingsRecord memory)
    {
        require(recordId < _savingsRecords.length, "invalid recordId");
        return _savingsRecords[recordId];
    }

    function getCurrentSavingsInterestRateWithData(bytes memory data)
        public
        view
        delegated
        initialized
        returns (uint256)
    {
        return _calculateSavingsInterestRate(MULTIPLIER);
    }

    function getCurrentSavingsAPRWithData(bytes memory data)
        public
        view
        delegated
        initialized
        returns (uint256)
    {
        return
            _newSavingsCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedSavingsInterestRateWithData(
        uint256 amount,
        bytes memory data
    ) public view delegated initialized returns (uint256) {
        return _calculateSavingsInterestRate(amount);
    }

    function getExpectedSavingsAPRWithData(uint256 amount, bytes memory data)
        public
        view
        delegated
        initialized
        returns (uint256)
    {
        return
            _newSavingsCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }

    function _withdraw(
        address user,
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) internal nonReentrant returns (bool) {
        require(recordId < _savingsRecords.length, "invalid recordId");

        SavingsRecord storage record = _savingsRecords[recordId];

        require(record.owner == user, "invalid owner");

        uint256 currentBalance = _getCurrentSavingsBalance(record);

        require(currentBalance >= amount, "insufficient balance");
        require(
            asset().balanceOf(address(this)) >= amount,
            "insufficient fund"
        );

        _totalFunds = _totalFunds.sub(record.balance).add(currentBalance).sub(
            amount
        );
        _paidInterests = _paidInterests.add(currentBalance.sub(record.balance));

        record.balance = currentBalance.sub(amount);
        record.lastTimestamp = block.timestamp;

        require(asset().transfer(user, amount), "transfer failed");

        emit SavingsWithdrawn(
            recordId,
            user,
            amount,
            record.balance,
            block.timestamp
        );

        return true;
    }

    function _getCurrentSavingsBalance(SavingsRecord memory record)
        internal
        view
        returns (uint256)
    {
        return
            _newSavingsCalculator.getExpectedBalance(
                record.balance,
                record.interestRate,
                block.timestamp - record.lastTimestamp
            );
    }

    function _calculateSavingsInterestRate(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return
            _newSavingsCalculator.getInterestRate(
                _totalFunds,
                _totalBorrows,
                amount
            );
    }
}
