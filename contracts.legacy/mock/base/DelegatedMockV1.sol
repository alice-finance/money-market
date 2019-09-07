pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../../base/DelegatedBase.sol";

contract DelegatedMockV1 is DelegatedBase {
    function initialize() public {
        require(_initialize(1));
    }

    uint256 private _calleeStateVar1 = 100;

    function increaseV1() public  delegated {
        _calleeStateVar1 += 1;
    }

    function decreaseV1() public  delegated {
        _calleeStateVar1 -= 1;
    }

    function getValueV1() public view  delegated returns (uint256) {
        return _calleeStateVar1;
    }

    function setValueV1(uint256 newValue) public  delegated {
        _calleeStateVar1 = newValue;
    }

    function revertV1() public view  delegated {
        revert("revert V1");
    }
}
