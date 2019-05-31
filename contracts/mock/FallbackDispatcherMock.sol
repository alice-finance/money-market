pragma solidity 0.5.8;

import "../base/FallbackDispatcher.sol";

contract FallbackDispatcherMock is FallbackDispatcher {
    constructor() public {
        _owner = msg.sender;
        _guardCounter = 1;

        _totalBorrows = 100;
        _totalFunds = 200;
    }
}
