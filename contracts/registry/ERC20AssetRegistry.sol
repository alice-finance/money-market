pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "./IERC20AssetRegistry.sol";
import "../staking/OperatorPortal.sol";

contract ERC20AssetRegistry is IERC20AssetRegistry {
    OperatorPortal private _portal;
    mapping(address => bool) private _registered;

    constructor(address portalAddress) public {
        _portal = OperatorPortal(portalAddress);
    }

    function assets() external returns (address[] memory) {
        return new address[](0);
    }

    function isRegistered(address asset) external returns (bool) {
        return _registered[asset];
    }

    function register(address) public returns (bool) {
        return false;
    }
    function unregister(address) public returns (bool) {
        return false;
    }
}
