pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../calculator/IInterestCalculator.sol";

contract Base {
    uint256 public constant DECIMALS = 18;
    uint256 public constant MULTIPLIER = 10 ** DECIMALS;

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
