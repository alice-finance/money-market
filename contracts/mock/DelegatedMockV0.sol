pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../base/DelegatedBase.sol";

contract DelegatedMockV0 is DelegatedBase {
    function initialize() public {
        require(_initialize(0));
    }

    uint256 private _calleeStateVar0 = 100;

    function increaseV0() public initialized delegated {
        _calleeStateVar0 += 1;
    }

    function decreaseV0() public initialized delegated {
        _calleeStateVar0 -= 1;
    }

    function getValueV0() public view initialized delegated returns (uint256) {
        return _calleeStateVar0;
    }

    function setValueV0(uint256 newValue) public initialized delegated {
        _calleeStateVar0 = newValue;
    }
}
