pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Constants.sol";
import "../ownership/Ownable.sol";

contract Asset is Constants, Ownable {
    IERC20 internal _asset;

    function asset() public view returns (IERC20) {
        return _asset;
    }
}
