pragma solidity 0.5.8;

import "./IERC20AssetRegistry.sol";
import "../staking/OperatorPortal.sol";

contract ERC20AssetRegistry is IERC20AssetRegistry {
    OperatorPortal private _portal;
    mapping(address => bool) private _registered;

    constructor(address portalAddress) public {
        _portal = OperatorPortal(portalAddress);
    }

    function register(address) public onlyOperator returns (bool) {
        return false;
    }
    function unregister(address) public returns (bool) {
        return false;
    }
}
