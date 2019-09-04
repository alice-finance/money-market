pragma solidity 0.5.8;

import "./Base.old.sol";

contract FallbackDispatcher is Base {
    function() external payable {
        _fallback();
    }

    function _fallback() internal {
        if (_loan != address(0)) {
            _delegate(_loan);
        }

        revert("cannot dispatch function");
    }

    function _delegate(address callee) internal {
        assembly {
            calldatacopy(0, 0, calldatasize)
            let result := delegatecall(gas, callee, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)

            switch result
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}
