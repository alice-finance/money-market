pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../base/Fund.sol";
import "./SavingsData.sol";
import "../ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Savings is Fund, SavingsData, ReentrancyGuard {
    using SafeMath for uint256;
    IInterestCalculator internal _newSavingsCalculator;

    function savingsCalculatorWithData(
        bytes memory /* data */
    ) public view delegated returns (IInterestCalculator) {
        return _newSavingsCalculator;
    }

    function setSavingsCalculatorWithData(
        IInterestCalculator calculator,
        bytes memory /* data */
    ) public delegated onlyOwner {
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
        returns (uint256)
    {
        return _deposit(msg.sender, amount, data);
    }

    function withdrawWithData(
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) public delegated returns (bool) {
        return _withdraw(msg.sender, recordId, amount, data);
    }

    function getSavingsRecordIdsWithData(
        address user,
        bytes memory /* data */
    ) public view delegated returns (uint256[] memory) {
        return _userSavingsRecordIds[user];
    }

    function getSavingsRecordsWithData(address user, bytes memory data)
        public
        view
        delegated
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getSavingsRecordWithData(ids[i], data);
        }

        return records;
    }

    function getSavingsRecordWithData(
        uint256 recordId,
        bytes memory /* data */
    ) public view delegated returns (SavingsRecord memory) {
        require(recordId < _savingsRecords.length, "invalid recordId");
        SavingsRecord memory record = _savingsRecords[recordId];

        record.balance = _getCurrentSavingsBalance(record);
        record.lastTimestamp = block.timestamp;

        return record;
    }

    function getRawSavingsRecordsWithData(
        address user,
        bytes memory /* data */
    ) public view delegated returns (SavingsRecord[] memory) {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = _savingsRecords[ids[i]];
        }

        return records;
    }

    function getRawSavingsRecordWithData(
        uint256 recordId,
        bytes memory /* data */
    ) public view delegated returns (SavingsRecord memory) {
        require(recordId < _savingsRecords.length, "invalid recordId");
        return _savingsRecords[recordId];
    }

    function getCurrentSavingsInterestRateWithData(
        bytes memory /* data */
    ) public view delegated returns (uint256) {
        return _calculateSavingsInterestRate(MULTIPLIER);
    }

    function getCurrentSavingsAPRWithData(
        bytes memory /* data */
    ) public view delegated returns (uint256) {
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
        bytes memory /* data */
    ) public view delegated returns (uint256) {
        return _calculateSavingsInterestRate(amount);
    }

    function getExpectedSavingsAPRWithData(
        uint256 amount,
        bytes memory /* data */
    ) public view delegated returns (uint256) {
        return
            _newSavingsCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }

    function _deposit(
        address user,
        uint256 amount,
        bytes memory /* data */
    ) internal nonReentrant returns (uint256) {
        require(amount > 0, "invalid amount");

        uint256 recordId = _savingsRecords.length;
        _savingsRecords.length += 1;

        _savingsRecords[recordId].id = recordId;
        _savingsRecords[recordId].owner = user;
        _savingsRecords[recordId].interestRate = _calculateSavingsInterestRate(
            amount
        );
        _savingsRecords[recordId].balance = amount;
        _savingsRecords[recordId].principal = amount;
        _savingsRecords[recordId].initialTimestamp = block.timestamp;
        _savingsRecords[recordId].lastTimestamp = block.timestamp;

        _userSavingsRecordIds[user].push(recordId);

        _totalFunds = _totalFunds.add(amount);

        require(asset().balanceOf(user) >= amount, "insufficient fund");
        require(
            asset().allowance(user, address(this)) >= amount,
            "allowance not met"
        );

        require(
            asset().transferFrom(user, address(this), amount),
            "transferFrom failed"
        );

        emit SavingsDeposited(
            recordId,
            user,
            amount,
            _savingsRecords[recordId].interestRate,
            block.timestamp
        );

        return recordId;
    }

    function _withdraw(
        address user,
        uint256 recordId,
        uint256 amount,
        bytes memory /* data */
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

    function _extractData(bytes memory data)
        internal
        pure
        returns (uint8, bytes memory)
    {
        bytes memory resultData = new bytes(data.length - 1);
        for (uint256 i = 0; i < data.length - 1; i++) {
            resultData[i] = data[i + 1];
        }
        return (uint8(data[0]), resultData);
    }
}
