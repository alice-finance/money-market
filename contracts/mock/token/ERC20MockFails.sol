pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract ERC20MockFails is ERC20Mintable, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint8 decimals)
        public
        ERC20Detailed(name, symbol, decimals)
    {}

    bool public shouldFail = true;
    bool public shouldRevert = false;

    function setShouldFail(bool value) public {
        shouldFail = value;
    }

    function setShouldRevert(bool value) public {
        shouldRevert = value;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        super.transfer(to, value);
        return _shouldFail();
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        super.transferFrom(from, to, value);
        return _shouldFail();
    }

    function _shouldFail() internal view returns (bool) {
        if (shouldFail) {
            if (shouldRevert) {
                revert("Token reverts");
            } else {
                return false;
            }
        }

        return true;
    }
}
