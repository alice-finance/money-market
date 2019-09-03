import "./SavingsBase.sol";

interface ISavings {
    struct SavingsRecord {
        uint256 id;
        address owner;
        uint256 interestRate;
        uint256 balance;
        uint256 principal;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    function depositWithData(uint256 amount, bytes data)
        public
        returns (uint256);

    function withdrawWithData(uint256 recordId, uint256 amount, bytes data)
        public
        returns (bool);

    function getSavingsRecordIdsWithData(address user, bytes data)
        public
        view
        returns (uint256[] memory);

    function getSavingsRecordsWithData(address user, bytes data)
        public
        view
        returns (SavingsRecord[] memory);

    function getSavingsRecordWithData(uint256 recordId, bytes data)
        public
        view
        returns (SavingsRecord memory);

    function getRawSavingsRecordsWithData(address user, bytes data)
        public
        view
        returns (SavingsRecord[] memory);

    function getRawSavingsRecordWithData(uint256 recordId, bytes data)
        public
        view
        returns (SavingsRecord memory);

    function getCurrentSavingsInterestRateWithData(bytes data)
        public
        view
        returns (uint256);

    function getCurrentSavingsAPRWithData(bytes data)
        public
        view
        returns (uint256);

    function getExpectedSavingsInterestRateWithData(uint256 amount, bytes data)
        public
        view
        returns (uint256);

    function getExpectedSavingsAPRWithData(uint256 amount, bytes data)
        public
        view
        returns (uint256);
}
