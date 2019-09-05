pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./Upgradable.sol";

contract Fund is Upgradable {
    uint256 internal _totalFunds;
    uint256 internal _totalBorrows;

    uint256 internal _earnedInterests;
    uint256 internal _paidInterests;

    function earnedInterests() public view returns (uint256) {
        return _earnedInterests;
    }

    function paidInterests() public view returns (uint256) {
        return _paidInterests;
    }

    function totalFunds() public view returns (uint256) {
        return _totalFunds;
    }

    function totalBorrows() public view returns (uint256) {
        return _totalBorrows;
    }
}
