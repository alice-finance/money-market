pragma solidity ^0.5.11;

interface IERC20AssetRegistry {
    function assets() external view returns (address[] memory);
    function isRegistered(address) external view returns (bool);
}
