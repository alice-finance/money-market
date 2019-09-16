pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../savings/InvitationOnlySavings.sol";
import "./ILoan.sol";
import "../registry/IERC20AssetRegistry.sol";
import "../calculator/ILoanInterestCalculator.sol";
import "../staking/OperatorPortal.sol";

contract LoanData is InvitationOnlySavings, ILoan {
    OperatorPortal internal _operatorPortal;
    IERC20AssetRegistry internal _ERC20AssetRegistry;
    ILoanInterestCalculator internal _loanInterestCalculator;
    uint256 internal _minimumCollateralRate;

    LoanRecord[] internal _loanRecords;
    mapping(address => uint256[]) internal _userLoanRecordIds;
    mapping(address => uint256) internal _collateralAmounts;

    event OperatorPortalChanged(
        address indexed previousPortal,
        address indexed newPortal
    );

    event LoanCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    event ERC20AssetRegistryChanged(
        address indexed previousRegistry,
        address indexed newRegistry
    );

    event MinimumCollateralRateChanged(uint256 previousRate, uint256 newRate);

    function operatorPortal() public view delegated returns (OperatorPortal) {
        return _operatorPortal;
    }

    function setOperatorPortal(OperatorPortal newPortal)
        public
        delegated
        onlyOwner
    {
        require(
            address(_operatorPortal) == address(0),
            "portal already setted"
        );
        require(address(newPortal) != address(0), "ZERO address");

        emit OperatorPortalChanged(
            address(_operatorPortal),
            address(newPortal)
        );
        _operatorPortal = newPortal;
    }

    function loanCalculatorWithData(
        bytes memory /* data */
    ) public view delegated returns (ILoanInterestCalculator) {
        return _loanInterestCalculator;
    }

    function setLoanCalculatorWithData(
        ILoanInterestCalculator calculator,
        bytes memory /* data */
    ) public delegated onlyOwner {
        require(address(calculator) != address(0), "ZERO address");

        emit LoanCalculatorChanged(
            address(_newSavingsCalculator),
            address(calculator)
        );
        _newSavingsCalculator = calculator;
    }

    function ERC20AssetRegistry()
        public
        view
        delegated
        returns (IERC20AssetRegistry)
    {
        return _ERC20AssetRegistry;
    }

    function setERC20AssetRegistry(IERC20AssetRegistry registry)
        public
        delegated
        onlyOwner
    {
        require(address(registry) != address(0), "ZERO address");

        emit LoanCalculatorChanged(
            address(_ERC20AssetRegistry),
            address(registry)
        );
        _ERC20AssetRegistry = registry;
    }

    function minimumCollateralRate() public view delegated returns (uint256) {
        return _minimumCollateralRate;
    }

    function setMinimumCollateralRate(uint256 newRate)
        public
        delegated
        onlyOwner
    {
        require(newRate >= MULTIPLIER, "invalid minimum collateral rate");

        emit MinimumCollateralRateChanged(_minimumCollateralRate, newRate);

        _minimumCollateralRate = newRate;
    }

    function collateralAmount(address collateral)
        public
        view
        delegated
        returns (uint256)
    {
        return _collateralAmounts[collateral];
    }

    function getLoanRecordIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _userLoanRecordIds[user];
    }

    function getLoanRecords(address user)
        public
        view
        returns (LoanRecord[] memory)
    {
        uint256[] storage ids = _userLoanRecordIds[user];
        LoanRecord[] memory records = new LoanRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getLoanRecord(ids[i]);
        }

        return records;
    }

    function getLoanRecord(uint256 recordId)
        public
        view
        returns (LoanRecord memory)
    {
        require(recordId < _loanRecords.length, "invalid recordId");
        LoanRecord memory record = _loanRecords[recordId];

        record.balance = _getCurrentLoanBalance(record);
        record.lastTimestamp = block.timestamp;

        return record;
    }

    function getRawLoanRecords(address user)
        public
        view
        returns (LoanRecord[] memory)
    {
        uint256[] storage ids = _userLoanRecordIds[user];
        LoanRecord[] memory records = new LoanRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = _loanRecords[ids[i]];
        }

        return records;
    }

    function getRawLoanRecord(uint256 recordId)
        public
        view
        returns (LoanRecord memory)
    {
        require(recordId < _loanRecords.length, "invalid recordId");
        return _loanRecords[recordId];
    }

    function getCurrentLoanInterestRate() public view returns (uint256) {
        return _calculateLoanInterestRate(MULTIPLIER);
    }

    function getCurrentLoanAPR() public view returns (uint256) {
        return
            _loanInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateLoanInterestRate(MULTIPLIER),
                    365 days
                ) -
                MULTIPLIER;
    }

    function getExpectedLoanInterestRate(uint256 amount)
        public
        view
        returns (uint256)
    {
        return _calculateLoanInterestRate(amount);
    }

    function getExpectedLoanAPR(uint256 amount) public view returns (uint256) {
        return
            _loanInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateLoanInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }

    function _getCurrentLoanBalance(LoanRecord memory record)
        internal
        view
        delegated
        returns (uint256)
    {
        return
            _loanInterestCalculator.getExpectedBalance(
                record.balance,
                record.interestRate,
                block.timestamp - record.lastTimestamp
            );
    }

    function _calculateLoanInterestRate(uint256 amount)
        internal
        view
        delegated
        returns (uint256)
    {
        return
            _loanInterestCalculator.getInterestRate(
                _totalFunds,
                _totalBorrows,
                amount
            );
    }

    function _calculateCollateralLoanInterestRate(
        uint256 amount,
        address collateral
    ) internal view delegated returns (uint256) {
        address[] memory collaterals = _ERC20AssetRegistry.assets();
        uint256[] memory amounts = new uint256[](collaterals.length);
        uint256 id = uint256(-1);
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i] == collateral) {
                id = i;
            }

            amounts[i] = _collateralAmounts[collaterals[i]];
        }

        return
            _loanInterestCalculator.getCollateralInterestRate(
                _totalFunds,
                _totalBorrows,
                amounts,
                id,
                amount
            );
    }
}
