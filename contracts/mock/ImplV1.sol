pragma solidity 0.5.8;

import "../base/Base.sol";

contract ImplV1 is Base {
    uint256 private _calleeStateVar1 = 100;

    function increase() public {
        _calleeStateVar1 += 1;
    }

    function decrease() public {
        _calleeStateVar1 -= 1;
    }

    function getValue() public view returns (uint256) {
        return _calleeStateVar1;
    }

    function setValue(uint256 newValue) public {
        _calleeStateVar1 = newValue;
    }
}
