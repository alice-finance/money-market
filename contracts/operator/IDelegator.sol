pragma solidity ^0.5.11;

interface IDelegator {
    function isDelegator() external view returns (bool);
    function isStakeRemovable(address asset, address operator)
        external
        view
        returns (bool);
}
