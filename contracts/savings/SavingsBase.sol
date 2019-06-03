pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../base/FallbackDispatcher.sol";
import "../ownership/TrustlessOwner.sol";

contract SavingsBase is FallbackDispatcher {
    using SafeMath for uint256;

    /** Events */
    event SavingsDeposited(
        uint256 recordId,
        address indexed owner,
        uint256 balance,
        uint256 rate,
        uint256 timestamp
    );

    event SavingsWithdrawn(
        uint256 recordId,
        address indexed owner,
        uint256 amount,
        uint256 remainingBalance,
        uint256 timestamp
    );

    /** Public functions */

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

        require(_asset.balanceOf(user) >= amount, "insufficient fund");
        require(
            _asset.allowance(user, address(this)) >= amount,
            "allowance not met"
        );

        _asset.transferFrom(user, address(this), amount);

        emit SavingsDeposited(
            recordId,
            user,
            amount,
            _savingsRecords[recordId].interestRate,
            block.timestamp
        );

        return recordId;
    }

    function _withdraw(address user, uint256 recordId, uint256 amount)
        internal
        nonReentrant
        returns (bool)
    {
        require(recordId < _savingsRecords.length, "invalid recordId");

        SavingsRecord storage record = _savingsRecords[recordId];

        require(record.owner == user, "invalid owner");

        uint256 currentBalance = _getCurrentSavingsBalance(record);

        require(currentBalance >= amount, "insufficient balance");
        require(_asset.balanceOf(address(this)) >= amount, "insufficient fund");

        _totalFunds = _totalFunds.sub(record.balance).add(currentBalance).sub(
            amount
        );
        _paidInterests = _paidInterests.add(currentBalance.sub(record.balance));

        record.balance = currentBalance.sub(amount);
        record.lastTimestamp = block.timestamp;

        _asset.transfer(user, amount);

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
        return _savingsInterestCalculator.getCurrentBalance(
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
        return _savingsInterestCalculator.getInterestRate(
            _totalFunds,
            _totalBorrows,
            amount
        );
    }
}
