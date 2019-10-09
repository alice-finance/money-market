pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IInterestCalculator {
    function getInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 amount
    ) external pure returns (uint256);

    function getExpectedBalance(
        uint256 principal,
        uint256 rate,
        uint256 timeDelta
    ) external pure returns (uint256);
}

contract Base {
    uint256 public constant DECIMALS = 18;
    uint256 public constant MULTIPLIER = 10**DECIMALS;

    address internal _owner;
    IERC20 internal _asset;
    IInterestCalculator internal _savingsInterestCalculator;
    address internal _loan;

    uint256 internal _totalFunds;
    uint256 internal _totalBorrows;

    uint256 internal _earnedInterests;
    uint256 internal _paidInterests;

    struct SavingsRecord {
        uint256 id;
        address owner;
        uint256 interestRate;
        uint256 balance;
        uint256 principal;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    SavingsRecord[] internal _savingsRecords;
    mapping(address => uint256[]) internal _userSavingsRecordIds;

    uint256 internal _guardCounter;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SavingsCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    event LoanChanged(address indexed previousLoan, address indexed newLoan);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "not called from owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "nonReentrant");
    }

    function asset() public view returns (IERC20) {
        return _asset;
    }

    function loan() public view returns (address) {
        return _loan;
    }

    function setLoan(address newLoanAddress) public onlyOwner {
        require(newLoanAddress != address(0), "ZERO address");

        emit LoanChanged(_loan, newLoanAddress);
        _loan = newLoanAddress;
    }

    function savingsCalculator() public view returns (IInterestCalculator) {
        return _savingsInterestCalculator;
    }

    function setSavingsCalculator(IInterestCalculator calculator)
        public
        onlyOwner
    {
        require(address(calculator) != address(0), "ZERO address");

        emit SavingsCalculatorChanged(
            address(_savingsInterestCalculator),
            address(calculator)
        );
        _savingsInterestCalculator = calculator;
    }

    function totalFunds() public view returns (uint256) {
        return _totalFunds;
    }

    function totalBorrows() public view returns (uint256) {
        return _totalBorrows;
    }
}

contract FallbackDispatcher is Base {
    function() external payable {
        _fallback();
    }

    function _fallback() internal {
        if (_loan != address(0)) {
            _delegate(_loan);
        }

        revert("cannot dispatch function");
    }

    function _delegate(address callee) internal {
        assembly {
            calldatacopy(0, 0, calldatasize)
            let result := delegatecall(gas, callee, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)

            switch result
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}

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
}

contract Savings is SavingsBase {
    function deposit(uint256 amount) public returns (uint256) {
        return _deposit(msg.sender, amount);
    }

    function withdraw(uint256 recordId, uint256 amount) public returns (bool) {
        return _withdraw(msg.sender, recordId, amount);
    }

    function getSavingsRecordIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _userSavingsRecordIds[user];
    }

    function getSavingsRecords(address user)
        public
        view
        returns (SavingsRecord[] memory)
    {
        uint256[] storage ids = _userSavingsRecordIds[user];
        SavingsRecord[] memory records = new SavingsRecord[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            records[i] = getSavingsRecord(ids[i]);
        }

        return records;
    }

    function getSavingsRecord(uint256 recordId)
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

    function getExpectedSavingsAPR(uint256 amount)
        public
        view
        returns (uint256)
    {
        return
            _savingsInterestCalculator.getExpectedBalance(
                    MULTIPLIER,
                    _calculateSavingsInterestRate(amount),
                    365 days
                ) -
                MULTIPLIER;
    }
}

contract MoneyMarket is Savings {
    constructor(
        address ownerAddress,
        address assetAddress,
        address savingsInterestCalculatorAddress
    ) public {
        _owner = ownerAddress;
        _asset = IERC20(assetAddress);
        _savingsInterestCalculator = IInterestCalculator(
            savingsInterestCalculatorAddress
        );
        _loan = address(0);

        _totalBorrows = 0;
        _totalFunds = 0;

        _earnedInterests = 0;
        _paidInterests = 0;

        _guardCounter = 1;
    }
}
