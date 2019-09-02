pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./DelegatedMockV1.sol";

contract DelegatedMockV2 is DelegatedMockV1 {
    function initialize() public {
        require(_initialize(2));
    }

    uint256 private _calleeStateVar2 = 200;

    function increaseV2() public delegated checkVersion(2) {
        _calleeStateVar2 += 1;
    }

    function decreaseV2() public delegated checkVersion(2) {
        _calleeStateVar2 -= 1;
    }

    function getValueV2()
        public
        view
        delegated
        checkVersion(2)
        returns (uint256)
    {
        return _calleeStateVar2;
    }

    function setValueV2(uint256 newValue) public delegated checkVersion(2) {
        _calleeStateVar2 = newValue;
    }

    function revertV2() public view delegated checkVersion(2) {
        revert("revert V2");
    }
}
