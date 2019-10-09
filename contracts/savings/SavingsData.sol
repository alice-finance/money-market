pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "./ISavings.sol";

contract SavingsData is ISavings {
    SavingsRecord[] internal _savingsRecords;
    mapping(address => uint256[]) internal _userSavingsRecordIds;
}
