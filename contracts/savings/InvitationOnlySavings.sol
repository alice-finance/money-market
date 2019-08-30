pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./Savings.sol";
import "../marketing/IInvitationRepository.sol";

contract InvitationOnlySavings is Savings {
    IInterestCalculator internal _savingsInterestCalculator2;
    IInvitationRepository internal _invitationRepository;
    uint256 internal _minimumSavingsAmount;

    event SavingsCalculator2Changed(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    event InvitationRepositoryChanged(
        address indexed previousRepository,
        address indexed newRepository
    );

    event MinimumSavingsAmountChanged(uint256 from, uint256 to);

    function savingsCalculator2() public view returns (IInterestCalculator) {
        return _savingsInterestCalculator2;
    }

    function setSavingsCalculator2(IInterestCalculator calculator)
        public
        onlyOwner
    {
        require(address(calculator) != address(0), "ZERO address");

        emit SavingsCalculatorChanged(
            address(_savingsInterestCalculator2),
            address(calculator)
        );
        _savingsInterestCalculator2 = calculator;
    }

    function setMinimumSavingsAmount(uint256 amount) public onlyOwner {
        emit MinimumSavingsAmountChanged(_minimumSavingsAmount, amount);
        _minimumSavingsAmount = amount;
    }

    function setInvitationRepository(IInvitationRepository invitationCode)
        public
        onlyOwner
    {
        emit InvitationRepositoryChanged(
            address(_invitationRepository),
            address(invitationCode)
        );
        _invitationRepository = invitationCode;
    }

    function deposit2(uint256 amount) public returns (uint256) {
        return _deposit2(msg.sender, amount);
    }

    function _calculateSavingsInterestRate2(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return
            _savingsInterestCalculator2.getInterestRate(
                _totalFunds,
                _totalBorrows,
                amount
            );
    }

    function getCurrentSavingsInterestRate2() public view returns (uint256) {
        return _calculateSavingsInterestRate2(MULTIPLIER);
    }

    function getCurrentSavingsAPR2() public view returns (uint256) {
        return
            _savingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate2(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedSavingsInterestRate2(uint256 amount)
        public
        view
        returns (uint256)
    {
        return _calculateSavingsInterestRate2(amount);
    }

    function getExpectedSavingsAPR2(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            _savingsInterestCalculator2.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate2(amount),
                    365 days
                ) -
                MULTIPLIER;
    }

    function _deposit2(address user, uint256 amount)
        internal
        nonReentrant
        returns (uint256)
    {
        require(amount > _minimumSavingsAmount, "invalid amount");
        require(
            _invitationRepository.isRegistered(user),
            "user does not registered invitation code"
        );

        uint256 recordId = _savingsRecords.length;
        _savingsRecords.length += 1;

        _savingsRecords[recordId].id = recordId;
        _savingsRecords[recordId].owner = user;
        _savingsRecords[recordId].interestRate = _calculateSavingsInterestRate2(
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
}
