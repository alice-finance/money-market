pragma solidity 0.5.8;

import "./BaseMock.sol";

contract ReentrancyAttack {
    function callback() public {
        bytes4 func = bytes4(keccak256("guardedFunction1(address)"));
        (bool success, bytes memory data) = msg.sender.call(
            abi.encodeWithSelector(func, address(this))
        );
        require(success, string(data));
    }
}
