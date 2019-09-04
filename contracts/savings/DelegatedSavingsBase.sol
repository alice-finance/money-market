pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../base/DelegatedBase.sol";

contract DelegatedSavingsBase is DelegatedBase {
    using SafeMath for uint256;

    IInterestCalculator internal _delegatedSavingsInterestCalculator;
    uint256 internal _minimumSavingsAmount;

    event MinimumSavingsAmountChanged(uint256 from, uint256 to);

    event DelegatedSavingsCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    function savingsInterestCalculator()
        public
        view
        delegated
        initialized
        returns (IInterestCalculator)
    {
        return _delegatedSavingsInterestCalculator;
    }

    function setSavingsInterestCalculator(IInterestCalculator calculator)
        public
        delegated
        initialized
        onlyOwner
    {
        require(address(calculator) != address(0), "ZERO address");

        emit SavingsCalculatorChanged(
            address(_delegatedSavingsInterestCalculator),
            address(calculator)
        );
        _delegatedSavingsInterestCalculator = calculator;
    }

    function minimumSavingsAmount()
        public
        view
        delegated
        initialized
        returns (uint256)
    {
        return _minimumSavingsAmount;
    }

    function setMinimumSavingsAmount(uint256 amount)
        public
        delegated
        initialized
        onlyOwner
    {
        emit MinimumSavingsAmountChanged(_minimumSavingsAmount, amount);
        _minimumSavingsAmount = amount;
    }

    function getSavingsRecordIdsWithData(address user, bytes memory data)
        public
        view
        returns (uint256[] memory)
    {
        return _userSavingsRecordIds[user];
    }

    function getSavingsRecordsWithData(address user, bytes memory data)
        public
        view
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

        for (uint256 i = 0; i < ids.length; i++) {
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

    function getCurrentSavingsInterestRate() public view returns (uint256) {
        return _calculateSavingsInterestRate(MULTIPLIER);
    }

    function getCurrentSavingsAPR() public view returns (uint256) {
        return
            _savingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedSavingsInterestRate(uint256 amount)
        public
        view
        returns (uint256)
    {
        return _calculateSavingsInterestRate(amount);
    }

    /** Internal functions */
    function _deposit(address user, uint256 amount)
        internal
        nonReentrant
        returns (uint256)
    {
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
            _savingsInterestCalculator.getExpectedBalance(
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
            _savingsInterestCalculator.getInterestRate(
                _totalFunds,
                _totalBorrows,
                amount
            );
    }

    function depositWithData(uint256 amount, bytes memory data)
        public
        delegated
        checkVersion(1)
        returns (uint256)
    {
        return _deposit(msg.sender, amount);
    }

    function withdrawWithData(
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) public delegated checkVersion(1) returns (bool) {
        return _withdraw(msg.sender, recordId, amount, data);
    }

    function getCurrentSavingsInterestRateWithData(bytes memory data)
        public
        view
        delegated
        checkVersion(1)
        returns (uint256)
    {
        return _calculateSavingsInterestRate(MULTIPLIER);
    }

    function getCurrentSavingsAPRWithData(bytes memory data)
        public
        view
        delegated
        checkVersion(1)
        returns (uint256)
    {
        return
            _delegatedSavingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedSavingsInterestRateWithData(uint256 amount)
        public
        view
        delegated
        checkVersion(1)
        returns (uint256)
    {
        return _calculateSavingsInterestRate(amount);
    }

    function getExpectedSavingsAPRWithData(uint256 amount)
        public
        view
        delegated
        checkVersion(1)
        returns (uint256)
    {
        return
            _delegatedSavingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }
}
