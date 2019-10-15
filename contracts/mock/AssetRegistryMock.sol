pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "../staking/IERC20AssetRegistry.sol";

contract AssetRegistryMock is IERC20AssetRegistry {
    mapping(address => bool) private _registered;
    address[] private _assets;

    event AssetRegistered(
        address indexed asset,
        address indexed registrator,
        uint256 timestamp
    );
    event AssetUnregistered(
        address indexed asset,
        address indexed unregistrator,
        uint256 timestamp
    );

    function assets() public view returns (address[] memory) {
        return _assets;
    }

    function isRegistered(address asset) public view returns (bool) {
        return _registered[asset];
    }

    function register(address asset) public returns (bool) {
        if (_registered[asset]) {
            return true;
        }

        _assets.push(asset);
        _registered[asset] = true;

        emit AssetRegistered(asset, msg.sender, block.timestamp);

        return false;
    }
}
