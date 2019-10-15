pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

interface ILoan {
    event LoanBorrowed(
        uint256 recordId,
        address indexed owner,
        uint256 balance,
        uint256 rate,
        address indexed collateral,
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
        address indexed collateral,
        uint256 collateralAmount,
        uint256 timestamp
    );
    event LoanLiquidated(
        uint256 recordId,
        address indexed owner,
        address indexed liquidator,
        uint256 amount,
        uint256 balance,
        address indexed collateral,
        uint256 collateralAmount,
        uint256 timestamp
    );
    event LoanClosed(
        uint256 recordId,
        address indexed owner,
        uint256 timestamp
    );

    struct LoanRecord {
        uint256 id;
        address owner;
        uint256 interestIndex;
        uint256 balance;
        uint256 principal;
        address collateral;
        uint256 collateralAmount;
        uint256 collateralRate;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        bytes calldata data
    ) external returns (uint256);
    function repay(uint256 recordId, uint256 amount, bytes calldata data)
        external
        returns (bool);
    function supplyCollateral(
        uint256 recordId,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount,
        bytes calldata data
    ) external returns (bool);
    function totalBorrowsByCollateral(address collateral)
        external
        view
        returns (uint256);

    function getLoanRecordIdsWithData(address user, bytes calldata data)
        external
        view
        returns (uint256[] memory);
    function getLoanRecordsWithData(address user, bytes calldata data)
        external
        view
        returns (LoanRecord[] memory);
    function getLoanRecordWithData(uint256 recordId, bytes calldata data)
        external
        view
        returns (LoanRecord memory);
    function getRawLoanRecordWithData(uint256 recordId, bytes calldata data)
        external
        view
        returns (LoanRecord memory);
    function getActiveLoanRecordsByCollateralWithData(
        address collateral,
        bytes calldata data
    ) external view returns (LoanRecord[] memory);
    function getDefaultLoanRecordsByCollateralWithData(
        address collateral,
        bytes calldata data
    ) external view returns (LoanRecord[] memory);
}
