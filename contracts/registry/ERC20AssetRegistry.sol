pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "./IERC20AssetRegistry.sol";
import "../staking/OperatorPortal.sol";

contract ERC20AssetRegistry is IERC20AssetRegistry {
    OperatorPortal private _portal;
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

    constructor(address portalAddress) public {
        _portal = OperatorPortal(portalAddress);
    }

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
    function unregister(address asset) public returns (bool) {
        require(_registered[asset], "asset is not registered");
        uint256 id = uint256(-1);

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == asset) {
                id = i;
                break;
            }
        }

        require(id != uint256(-1), "cannot find asset");

        _assets[id] = _assets[_assets.length - 1];
        _assets.length -= 1;
        _registered[asset] = false;

        emit AssetUnregistered(asset, msg.sender, block.timestamp);

        return true;
    }
}
