pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../savings/DelegatedSavingsBase.sol";

contract DelegatedSavingsBaseMock is DelegatedSavingsBase {
    function initialize() public {
        _initialize(1);
    }
}
