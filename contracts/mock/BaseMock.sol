pragma solidity 0.5.8;

import "../base/Base.sol";
import "./ReentrancyAttack.sol";

contract BaseMock is Base {
    uint256 private _count = 5;
    constructor() public {
        _owner = msg.sender;
        _guardCounter = 1;

        _totalBorrows = 100;
        _totalFunds = 200;
    }

    function prohibitedFunction() public view onlyOwner returns (bool) {
        return true;
    }
    function setCount(uint256 newCount) public {
        _count = newCount;
    }
    function guardedFunction1(address externalContract) public nonReentrant {
        if (_count > 0) {
            _count -= 1;
            ReentrancyAttack(externalContract).callback();
        }
    }

    function guardedFunction2() public nonReentrant {
        if (_count > 0) {
            _count -= 1;
            guardedFunction2();
        }
    }

    function guardedFunction3() public nonReentrant {
        if (_count > 0) {
            _count -= 1;
            bytes4 func = bytes4(keccak256("guardedFunction3()"));
            (bool success, bytes memory data) = address(this).call(
                abi.encodeWithSelector(func)
            );
            require(success, string(data));
        }
    }
}
