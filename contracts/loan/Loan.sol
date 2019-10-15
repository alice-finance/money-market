pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "../savings/InvitationOnlySavings.sol";
import "./ILoan.sol";
import "../calculator/ILoanInterestCalculator.sol";
import "./LoanData.sol";

contract Loan is LoanData {
    using SafeMath for uint256;

    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        bytes memory data
    ) public returns (uint256) {
        return _borrow(msg.sender, amount, collateral, collateralAmount, data);
    }

    function repay(uint256 recordId, uint256 amount, bytes memory data)
        public
        returns (bool)
    {
        return _repay(msg.sender, recordId, amount, data);
    }

    function supplyCollateral(
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        return _supplyCollateral(msg.sender, recordId, amount, data);
    }

    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount,
        bytes memory data
    ) public returns (bool) {
        return _liquidate(msg.sender, recordId, amount, collateralAmount, data);
    }

    function _borrow(
        address account,
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        bytes memory /* data */
    ) internal nonReentrant returns (uint256) {
        updateIndex(collateral);
        require(amount > 0, "invalid amount");
        require(collateralAmount > 0, "invalid collateral amount");
        require(
            _ERC20AssetRegistry.isRegistered(collateral),
            "invalid collateral"
        );

        require(
            IERC20(collateral).balanceOf(account) >= collateralAmount,
            "insufficient collateral"
        );
        require(
            IERC20(collateral).allowance(account, address(this)) >=
                collateralAmount,
            "allowance not met"
        );

        uint256 balance = amount;
        uint256 collateralRate = _calculateCollateralRate(
            balance,
            collateral,
            collateralAmount
        );
        uint256 minRate = _minimumCollateralRate;

        require(collateralRate >= minRate, "need more collateral");

        uint256 recordId = _loanRecords.length;
        _loanRecords.length += 1;

        _loanRecords[recordId].id = recordId;
        _loanRecords[recordId].owner = account;
        _loanRecords[recordId].interestIndex = _collateralIndex[collateral];
        _loanRecords[recordId].balance = balance;
        _loanRecords[recordId].principal = balance;
        _loanRecords[recordId].collateral = collateral;
        _loanRecords[recordId].collateralAmount = collateralAmount;
        _loanRecords[recordId].collateralRate = collateralRate;
        _loanRecords[recordId].initialTimestamp = block.timestamp;
        _loanRecords[recordId].lastTimestamp = block.timestamp;

        _userLoanRecordIds[account].push(recordId);
        _activeLoanRecordIds[collateral].push(recordId);

        _totalBorrows += balance;
        _totalBorrowsByCollateral[collateral] -= balance;
        _totalCollateralAmount[collateral] += collateralAmount;

        require(
            asset().balanceOf(address(this)) >= amount,
            "insufficient fund"
        );

        require(
            IERC20(collateral).transferFrom(
                account,
                address(this),
                collateralAmount
            ),
            "transferFrom failed"
        );
        require(asset().transfer(account, balance), "transfer failed");

        emit LoanBorrowed(
            recordId,
            account,
            balance,
            collateralRate,
            collateral,
            collateralAmount,
            block.timestamp
        );

        return recordId;
    }

    function _repay(
        address account,
        uint256 recordId,
        uint256 amount,
        bytes memory /* data */
    ) internal nonReentrant returns (bool) {
        require(amount > 0, "invalid amount");
        require(recordId < _loanRecords.length, "invalid recordId");

        LoanRecord storage record = _loanRecords[recordId];

        updateIndex(record.collateral);

        require(record.owner == account, "invalid owner");

        require(
            asset().balanceOf(account) >= amount,
            "insufficient asset amount"
        );
        require(
            asset().allowance(account, address(this)) >= amount,
            "allowance not met"
        );

        uint256 currentBalance = _getCurrentLoanBalance(record);

        require(currentBalance >= amount, "repaying too much");

        uint256 collateralRate = _calculateCollateralRate(
            currentBalance,
            record.collateral,
            record.collateralAmount
        );

        _totalBorrows -= record.balance + currentBalance - amount;
        _totalBorrowsByCollateral[record.collateral] -=
            record.balance +
            currentBalance -
            amount;
        record.balance = currentBalance - amount;
        record.collateralRate = collateralRate;
        record.interestIndex = _collateralIndex[record.collateral];
        record.lastTimestamp = block.timestamp;

        asset().transferFrom(account, address(this), amount);

        emit LoanRepaid(
            recordId,
            account,
            amount,
            record.balance,
            block.timestamp
        );

        // Loan Closed
        if (record.balance == 0) {
            uint256 collateralAmount = record.collateralAmount;
            record.collateralAmount = 0;

            IERC20(record.collateral).transfer(account, collateralAmount);
            _totalCollateralAmount[record.collateral] -= collateralAmount;
            _removeFromActiveLoanRecord(record.collateral, record.id);

            emit LoanClosed(recordId, account, block.timestamp);
        }

        return true;
    }

    function _supplyCollateral(
        address account,
        uint256 recordId,
        uint256 amount,
        bytes memory /* data */
    ) internal nonReentrant returns (bool) {
        require(recordId < _loanRecords.length, "invalid recordId");
        require(amount > 0, "invalid collateral amount");

        LoanRecord storage record = _loanRecords[recordId];
        updateIndex(record.collateral);

        require(record.owner == account, "invalid owner");

        require(
            IERC20(record.collateral).balanceOf(account) >= amount,
            "insufficient collateral amount"
        );
        require(
            IERC20(record.collateral).allowance(account, address(this)) >=
                amount,
            "allowance not met"
        );

        record.collateralAmount = record.collateralAmount + amount;

        uint256 currentBalance = _getCurrentLoanBalance(record);
        uint256 collateralRate = _calculateCollateralRate(
            currentBalance,
            record.collateral,
            record.collateralAmount
        );

        _totalBorrows = _totalBorrows - record.balance + currentBalance;
        record.balance = currentBalance;
        record.collateralRate = collateralRate;
        record.interestIndex = _collateralIndex[record.collateral];
        record.lastTimestamp = block.timestamp;

        IERC20(record.collateral).transferFrom(account, address(this), amount);

        emit LoanCollateralSupplied(
            recordId,
            record.owner,
            amount,
            record.collateral,
            record.collateralAmount,
            block.timestamp
        );

        return true;
    }

    function _liquidate(
        address liquidator,
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount,
        bytes memory /* data */
    ) internal returns (bool) {
        require(amount > 0, "invalid amount");
        require(recordId < _loanRecords.length, "invalid recordId");

        LoanRecord storage record = _loanRecords[recordId];
        updateIndex(record.collateral);

        require(record.owner != liquidator, "invalid owner");

        require(
            asset().balanceOf(liquidator) >= amount,
            "insufficient asset amount"
        );
        require(
            asset().allowance(liquidator, address(this)) >= amount,
            "allowance not met"
        );

        uint256 currentBalance = _getCurrentLoanBalance(record);
        uint256 collateralPrice = _priceSource.getLastPrice(record.collateral);
        uint256 value = (record.collateralAmount * collateralPrice) /
            MULTIPLIER;

        require(value == amount, "invalid amount");

        uint256 collateralRate = _calculateCollateralRate(
            currentBalance,
            record.collateral,
            record.collateralAmount
        );

        require(
            collateralRate <= _defaultCollateralRate,
            "loan is not on default"
        );

        _totalBorrows -= record.balance;
        _totalBorrowsByCollateral[record.collateral] -= record.balance;
        _totalCollateralAmount[record.collateral] -= collateralAmount;
        _removeFromActiveLoanRecord(record.collateral, record.id);
        record.balance = 0;
        record.collateralRate = collateralRate;
        record.collateralAmount = 0;
        record.interestIndex = _collateralIndex[record.collateral];
        record.lastTimestamp = block.timestamp;

        asset().transferFrom(liquidator, address(this), amount);
        IERC20(record.collateral).transfer(liquidator, collateralAmount);

        emit LoanLiquidated(
            recordId,
            record.owner,
            liquidator,
            amount,
            record.balance,
            record.collateral,
            record.collateralAmount,
            block.timestamp
        );

        emit LoanClosed(recordId, record.owner, block.timestamp);

        return true;
    }
}
