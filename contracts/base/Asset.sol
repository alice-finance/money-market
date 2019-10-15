pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Asset is Ownable {
    IERC20 internal _asset;

    function asset() public view returns (IERC20) {
        return _asset;
    }
}
