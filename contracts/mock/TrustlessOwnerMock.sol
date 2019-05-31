pragma solidity 0.5.8;

import "../ownership/TrustlessOwner.sol";

contract TrustlessOwnerMock is TrustlessOwner {
    function executePendingTransactions() public {
        // do nothing
    }
}
