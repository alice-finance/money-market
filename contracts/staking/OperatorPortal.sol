pragma solidity 0.5.8;

contract OperatorPortal {
    struct Asset {
        address addr;
        uint256 stakedAmount;
    }
    struct Operator {
        address assetAddress;
        uint256 stakedAmount;
    }

    address private _owner; // DeferredOwner

    function assets() public returns (Asset[] memory);
    function asset(address assetAddress) public returns (Asset memory);
    function totalStakedAmount() public returns (uint256);
    function assetsOf(address operator) public returns (Asset[] memory);
    function operatorsOf(address assetAddress)
        public
        returns (Operator[] memory);

    function stake(address assetAddress, uint256 amount) public;
    function unstake(address assetAddress, uint256 amount) public;
    function pendingBalanceOf() public;
    function withdraw() public;

    function delegator() public;
    function isDelegator() public;
    function addDelegator() public onlyOwner;
    function removeDelegator() public onlyOwner;
    function slash() public onlyDelegator;
}
