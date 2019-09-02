pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

interface IMoneyMarket {
    struct SavingsRecord {
        uint256 id;
        address owner;
        uint256 interestRate;
        uint256 balance;
        uint256 principal;
        uint256 initialTimestamp;
        uint256 lastTimestamp;
    }

    function totalFunds() external view returns (uint256);

    function getSavingsRecord(uint256 recordId)
        external
        view
        returns (SavingsRecord memory);

    function getSavingsRecords(address user)
        external
        view
        returns (SavingsRecord[] memory);

    function getSavingsRecordIds(address user)
        external
        view
        returns (uint256[] memory);
}
