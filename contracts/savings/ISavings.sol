pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

interface ISavings {
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

    struct SavingsRecord {
        uint256 id;
        address owner;
        uint256 interestRate;
        uint256 balance;
        uint256 principal;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    function depositWithData(uint256 amount, bytes calldata data)
        external
        returns (uint256);

    function withdrawWithData(
        uint256 recordId,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function getSavingsRecordIdsWithData(address user, bytes calldata data)
        external
        view
        returns (uint256[] memory);

    function getSavingsRecordsWithData(address user, bytes calldata data)
        external
        view
        returns (SavingsRecord[] memory);

    function getSavingsRecordWithData(uint256 recordId, bytes calldata data)
        external
        view
        returns (SavingsRecord memory);

    function getRawSavingsRecordsWithData(address user, bytes calldata data)
        external
        view
        returns (SavingsRecord[] memory);

    function getRawSavingsRecordWithData(uint256 recordId, bytes calldata data)
        external
        view
        returns (SavingsRecord memory);

    function getCurrentSavingsInterestRateWithData(bytes calldata data)
        external
        view
        returns (uint256);

    function getCurrentSavingsAPRWithData(bytes calldata data)
        external
        view
        returns (uint256);

    function getExpectedSavingsInterestRateWithData(
        uint256 amount,
        bytes calldata data
    ) external view returns (uint256);

    function getExpectedSavingsAPRWithData(uint256 amount, bytes calldata data)
        external
        view
        returns (uint256);
}
