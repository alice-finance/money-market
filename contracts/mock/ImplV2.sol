pragma solidity 0.5.8;

import "./ImplV1.sol";

contract ImplV2 is ImplV1 {
    uint256 private _calleeStateVar2 = 100;

    function increaseV2() public {
        _calleeStateVar2 += 1;
    }

    function decreaseV2() public {
        _calleeStateVar2 -= 1;
    }

    function getValueV2() public view returns (uint256) {
        return _calleeStateVar2;
    }

    function setValueV2(uint256 newValue) public {
        _calleeStateVar2 = newValue;
    }
}
