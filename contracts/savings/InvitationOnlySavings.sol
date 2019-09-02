pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./Savings.sol";
import "../marketing/IInvitationRepository.sol";
import "../base/DelegatedBase.sol";

contract InvitationOnlySavings is DelegatedBase, Savings {
    IInterestCalculator internal _invitationOnlySavingsInterestCalculator;
    IInvitationRepository internal _invitationRepository;
    uint256 internal _minimumSavingsAmount;

    event InvitationOnlySavingsCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    event InvitationRepositoryChanged(
        address indexed previousRepository,
        address indexed newRepository
    );

    event MinimumSavingsAmountChanged(uint256 from, uint256 to);

    function initialize(
        IInterestCalculator zeroCalculator,
        IInterestCalculator invitationOnlySavingsCalculator,
        IInvitationRepository invitationRepository,
        uint256 minimumSavingsAmount
    ) public {
        require(_initialize(1));

        setSavingsCalculator(zeroCalculator);
        setInvitationOnlySavingsCalculator(invitationOnlySavingsCalculator);
        setInvitationRepository(invitationRepository);
        setMinimumSavingsAmount(minimumSavingsAmount);
    }

    function invitationOnlySavingsCalculator()
        public
        view
        initialized
        delegated
        returns (IInterestCalculator)
    {
        return _invitationOnlySavingsInterestCalculator;
    }

    function setInvitationOnlySavingsCalculator(IInterestCalculator calculator)
        public
        initialized
        delegated
        onlyOwner
    {
        require(
            address(calculator) != address(0),
            "new calculator is zero address"
        );

        emit InvitationOnlySavingsCalculatorChanged(
            address(_invitationOnlySavingsInterestCalculator),
            address(calculator)
        );
        _invitationOnlySavingsInterestCalculator = calculator;
    }

    function invitationRepository()
        public
        view
        initialized
        delegated
        returns (IInvitationRepository)
    {
        return _invitationRepository;
    }

    function setInvitationRepository(IInvitationRepository repository)
        public
        initialized
        delegated
        onlyOwner
    {
        require(
            address(repository) != address(0),
            "new invitation repository is zero address"
        );

        emit InvitationRepositoryChanged(
            address(_invitationRepository),
            address(repository)
        );
        _invitationRepository = repository;
    }

    function minimumSavingsAmount()
        public
        view
        initialized
        delegated
        returns (uint256)
    {
        return _minimumSavingsAmount;
    }

    function setMinimumSavingsAmount(uint256 amount)
        public
        initialized
        delegated
        onlyOwner
    {
        emit MinimumSavingsAmountChanged(_minimumSavingsAmount, amount);
        _minimumSavingsAmount = amount;
    }

    function invitationOnlyDeposit(uint256 amount)
        public
        initialized
        delegated
        returns (uint256)
    {
        return _invitationOnlyDeposit(msg.sender, amount);
    }

    function _calculateInvitationOnlySavingsInterestRate(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return
            _invitationOnlySavingsInterestCalculator.getInterestRate(
                _totalFunds,
                _totalBorrows,
                amount
            );
    }

    function getCurrentInvitationOnlySavingsInterestRate()
        public
        view
        initialized
        delegated
        returns (uint256)
    {
        return _calculateInvitationOnlySavingsInterestRate(MULTIPLIER);
    }

    function getCurrentInvitationOnlySavingsAPR()
        public
        view
        initialized
        delegated
        returns (uint256)
    {
        return
            _savingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateInvitationOnlySavingsInterestRate(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedInvitationOnlySavingsInterestRate(uint256 amount)
        public
        view
        initialized
        delegated
        returns (uint256)
    {
        return _calculateInvitationOnlySavingsInterestRate(amount);
    }

    function getExpectedInvitationOnlySavingsAPR(uint256 amount)
        public
        view
        initialized
        delegated
        returns (uint256)
    {
        return
            _invitationOnlySavingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateInvitationOnlySavingsInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }

    function _invitationOnlyDeposit(address user, uint256 amount)
        internal
        nonReentrant
        returns (uint256)
    {
        require(amount >= _minimumSavingsAmount, "invalid amount");
        require(
            _invitationRepository.isRegistered(user),
            "user does not registered invitation code"
        );

        uint256 recordId = _savingsRecords.length;
        _savingsRecords.length += 1;

        _savingsRecords[recordId].id = recordId;
        _savingsRecords[recordId].owner = user;
        _savingsRecords[recordId]
            .interestRate = _calculateInvitationOnlySavingsInterestRate(amount);
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
