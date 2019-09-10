pragma solidity 0.5.8;

interface IERC20AssetRegistry {
    function assets() external returns (address[] memory);
    function isRegistered(address) external returns (bool);
}
