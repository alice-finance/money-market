pragma solidity ^0.5.11;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract ERC20Mock is ERC20Mintable, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint8 decimals)
        public
        ERC20Detailed(name, symbol, decimals)
    {}

    function burnAll(address account) public {
        _burn(account, balanceOf(account));
    }
}
