pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./Asset.sol";
import "../calculator/IInterestCalculator.sol";

contract Upgradable is Asset {
    IInterestCalculator internal _savingsInterestCalculator; // DEPRECATED
    address internal _loan;

    event SavingsCalculatorChanged(
        address indexed previousCalculator,
        address indexed newCalculator
    );

    event LoanChanged(address indexed previousLoan, address indexed newLoan);

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

    modifier delegated() {
        require(
            _loan != address(0) && _loan != address(this),
            "cannot call this contract directly"
        );
        _;
    }
}
