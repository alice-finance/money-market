pragma solidity 0.5.8;

import "../base/Base.sol";

contract InvalidImpl is Base {
    function invalidFunction() public pure returns (bool) {
        return true;
    }
}
