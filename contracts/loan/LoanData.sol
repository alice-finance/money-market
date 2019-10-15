pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "../savings/InvitationOnlySavings.sol";
import "./ILoan.sol";
import "../staking/IOperatorPortal.sol";
import "../staking/IERC20AssetRegistry.sol";
import "../staking/IPriceSource.sol";
import "../calculator/ILoanInterestCalculator.sol";

contract LoanData is InvitationOnlySavings, ILoan {
    // External contracts
    IOperatorPortal internal _operatorPortal;
    IERC20AssetRegistry internal _ERC20AssetRegistry;
    IPriceSource internal _priceSource;
    ILoanInterestCalculator internal _loanInterestCalculator;

    // Collateral Rate
    uint256 internal _defaultCollateralRate = 1490000000000000000; // 1.49
    uint256 internal _minimumCollateralRate = 1500000000000000000; // 1.5
    uint256 internal _dangerCollateralRate = 1600000000000000000; // 1.6

    // Loan Index
    mapping(address => uint256) internal _collateralIndex;
    mapping(address => uint256) internal _collateralIndexTimestamp;

    // Loan Records
    LoanRecord[] internal _loanRecords;
    mapping(address => uint256[]) internal _userLoanRecordIds;
    mapping(address => uint256[]) internal _activeLoanRecordIds;

    // Collateral
    mapping(address => uint256) internal _totalCollateralAmount;
    mapping(address => uint256) internal _totalBorrowsByCollateral;

    // Events
    event OperatorPortalChanged(
        address indexed previousPortal,
        address indexed newPortal
    );
    event LoanCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );
    event PriceSourceChanged(
        address indexed previousPriceSource,
        address indexed newPriceSource
    );
    event ERC20AssetRegistryChanged(
        address indexed previousRegistry,
        address indexed newRegistry
    );
    event DefaultCollateralRateChanged(uint256 previousRate, uint256 newRate);
    event MinimumCollateralRateChanged(uint256 previousRate, uint256 newRate);
    event DangerCollateralRateChanged(uint256 previousRate, uint256 newRate);

    /* Getters */

    function operatorPortal() public view returns (IOperatorPortal) {
        return _operatorPortal;
    }

    function setOperatorPortal(IOperatorPortal newPortal) public onlyOwner {
        require(address(newPortal) != address(0), "ZERO address");

        emit OperatorPortalChanged(
            address(_operatorPortal),
            address(newPortal)
        );
        _operatorPortal = newPortal;
    }

    function loanCalculatorWithData(
        bytes memory /* data */
    ) public view returns (ILoanInterestCalculator) {
        return _loanInterestCalculator;
    }

    function setLoanCalculatorWithData(
        ILoanInterestCalculator calculator,
        bytes memory /* data */
    ) public onlyOwner {
        require(address(calculator) != address(0), "ZERO address");

        emit LoanCalculatorChanged(
            address(_loanInterestCalculator),
            address(calculator)
        );
        _loanInterestCalculator = calculator;
    }

    function ERC20AssetRegistry() public view returns (IERC20AssetRegistry) {
        return _ERC20AssetRegistry;
    }

    function setERC20AssetRegistry(IERC20AssetRegistry registry)
        public
        onlyOwner
    {
        require(address(registry) != address(0), "ZERO address");

        emit LoanCalculatorChanged(
            address(_ERC20AssetRegistry),
            address(registry)
        );
        _ERC20AssetRegistry = registry;
    }

    function priceSource() public view returns (IPriceSource) {
        return _priceSource;
    }

    function setPriceSource(IPriceSource source) public onlyOwner {
        require(address(source) != address(0), "ZERO address");

        emit PriceSourceChanged(address(_priceSource), address(source));

        _priceSource = source;
    }

    function minimumCollateralRate() public view returns (uint256) {
        return _minimumCollateralRate;
    }

    function setMinimumCollateralRate(uint256 newRate) public onlyOwner {
        require(newRate >= MULTIPLIER, "invalid minimum collateral rate");

        emit MinimumCollateralRateChanged(_minimumCollateralRate, newRate);

        _minimumCollateralRate = newRate;
    }

    function setDefaultCollateralRate(uint256 newRate) public onlyOwner {
        require(newRate >= MULTIPLIER, "invalid default collateral rate");

        emit DefaultCollateralRateChanged(_defaultCollateralRate, newRate);

        _defaultCollateralRate = newRate;
    }

    function setDangerCollateralRate(uint256 newRate) public onlyOwner {
        require(newRate >= MULTIPLIER, "invalid danger collateral rate");

        emit DangerCollateralRateChanged(_dangerCollateralRate, newRate);

        _dangerCollateralRate = newRate;
    }

    function totalCollateralAmount(address collateral)
        public
        view
        returns (uint256)
    {
        return _totalCollateralAmount[collateral];
    }

    function totalBorrowsByCollateral(address collateral)
        public
        view
        returns (uint256)
    {
        return _totalBorrowsByCollateral[collateral];
    }

    /* Get loan records */

    function getLoanRecordIdsWithData(
        address user,
        bytes memory /* data */
    ) public view returns (uint256[] memory) {
        return _userLoanRecordIds[user];
    }

    function getLoanRecordsWithData(address user, bytes memory data)
        public
        view
        returns (LoanRecord[] memory)
    {
        uint256[] storage ids = _userLoanRecordIds[user];
        LoanRecord[] memory records = new LoanRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getLoanRecordWithData(ids[i], data);
        }

        return records;
    }

    function getLoanRecordWithData(
        uint256 recordId,
        bytes memory /* data */
    ) public view returns (LoanRecord memory) {
        require(recordId < _loanRecords.length, "invalid recordId");
        LoanRecord memory record = _loanRecords[recordId];

        record.balance = _getCurrentLoanBalance(record);
        record.collateralRate = _getCurrentCollateralRate(record);
        record.lastTimestamp = block.timestamp;

        return record;
    }

    function getRawLoanRecordsWithData(
        address user,
        bytes memory /* data */
    ) public view returns (LoanRecord[] memory) {
        uint256[] storage ids = _userLoanRecordIds[user];
        LoanRecord[] memory records = new LoanRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = _loanRecords[ids[i]];
        }

        return records;
    }

    function getRawLoanRecordWithData(
        uint256 recordId,
        bytes memory /* data */
    ) public view returns (LoanRecord memory) {
        require(recordId < _loanRecords.length, "invalid recordId");
        return _loanRecords[recordId];
    }

    function getActiveLoanRecordsByCollateralWithData(
        address collateral,
        bytes memory data
    ) public view returns (LoanRecord[] memory) {
        uint256[] storage ids = _activeLoanRecordIds[collateral];
        LoanRecord[] memory records = new LoanRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getLoanRecordWithData(ids[i], data);
        }

        return records;
    }

    function getDefaultLoanRecordsByCollateralWithData(
        address collateral,
        bytes memory data
    ) public view returns (LoanRecord[] memory) {
        uint256[] storage ids = _activeLoanRecordIds[collateral];
        LoanRecord[] memory records = new LoanRecord[](ids.length);
        uint256 length = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            LoanRecord memory record = getLoanRecordWithData(ids[i], data);
            if (_isDefaultLoan(record)) {
                records[length] = record;
                length += 1;
            }
        }

        // @dev to truncate memory array
        assembly {
            mstore(records, length)
        }

        return records;
    }

    function _removeFromActiveLoanRecord(address collateral, uint256 recordId)
        internal
    {
        uint256[] storage recordIds = _activeLoanRecordIds[collateral];
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (recordIds[i] == recordId) {
                recordIds[i] = recordIds[recordIds.length - 1];
                recordIds.length -= 1;
                return;
            }
        }
    }

    /* Get collateral info */

    function _getCurrentCollateralRate(LoanRecord memory record)
        internal
        view
        returns (uint256)
    {
        return
            _calculateCollateralRate(
                record.balance,
                record.collateral,
                record.collateralAmount
            );
    }

    function _isDefaultLoan(LoanRecord memory record)
        internal
        view
        returns (bool)
    {
        return _defaultCollateralRate >= _getCurrentCollateralRate(record);
    }

    function _calculateCollateralRate(
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) internal view returns (uint256) {
        uint256 assetPrice = _priceSource.getLastPrice(address(asset()));
        uint256 collateralPrice = _priceSource.getLastPrice(
            address(collateral)
        );

        return
            collateralAmount
                .mul(collateralPrice)
                .div(amount.mul(assetPrice))
                .mul(MULTIPLIER);
    }

    /* Get Loan Interest Rates */

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
        returns (uint256)
    {
        return
            _loanInterestCalculator.getExpectedBalanceWithIndex(
                record.balance,
                record.interestIndex,
                _collateralIndex[record.collateral]
            );
    }

    function _calculateLoanInterestRate(uint256 amount)
        internal
        view
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
    ) internal view returns (uint256) {
        address[] memory collateralList = _ERC20AssetRegistry.assets();
        uint256[] memory amounts = new uint256[](collateralList.length);
        uint256 id = uint256(-1);
        for (uint256 i = 0; i < collateralList.length; i++) {
            if (collateralList[i] == collateral) {
                id = i;
            }

            amounts[i] = _totalCollateralAmount[collateralList[i]];
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

    /* Update collateral interestIndex */
    function updateIndex(address collateral) public {
        uint256 previous = _collateralIndex[collateral];
        if (previous > 0) {
            uint256 timeDiff = block.timestamp -
                _collateralIndexTimestamp[collateral];
            uint256 currentRate = _calculateCollateralLoanInterestRate(
                MULTIPLIER,
                collateral
            );
            _collateralIndex[collateral] = _loanInterestCalculator
                .calculateIndex(previous, currentRate, timeDiff);
        } else {
            _collateralIndex[collateral] = MULTIPLIER;
        }
        _collateralIndexTimestamp[collateral] = block.timestamp;
    }
}
