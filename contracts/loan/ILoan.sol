pragma solidity 0.5.8;

interface ILoan {
    event LoanBorrowed(
        uint256 recordId,
        address indexed owner,
        uint256 balance,
        uint256 rate,
        address collateral,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event LoanRepaid(
        uint256 recordId,
        address indexed owner,
        uint256 amount,
        uint256 remainingBalance,
        uint256 timestamp
    );

    event LoanCollateralSupplied(
        uint256 recordId,
        address indexed owner,
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event LoanLiquidated(
        uint256 recordId,
        address indexed owner,
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        uint256 timestamp
    );

    struct LoanRecord {
        uint256 id;
        address owner;
        uint256 interestRate;
        uint256 balance;
        uint256 principal;
        address collateral;
        uint256 collateralAmount;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) external returns (uint256);
    function repay(uint256 recordId, uint256 amount) external returns (bool);
    function supplyCollateral(uint256 recordId, uint256 amount)
        external
        returns (bool);
    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount
    ) external returns (bool);
}
