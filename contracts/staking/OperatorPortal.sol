pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

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

    modifier onlyOwner() {
        _;
    }

    modifier onlyDelegator {
        _;
    }

    function assets() public returns (Asset[] memory) {
        return new Asset[](0);
    }

    function asset(address assetAddress) public returns (Asset memory) {
        return Asset(address(0), 0);
    }

    function totalStakedAmount() public returns (uint256) {
        return 0;
    }

    function assetsOf(address operator) public returns (Asset[] memory) {
        return new Asset[](0);
    }

    function operatorsOf(address assetAddress)
        public
        returns (Operator[] memory)
    {
        return new Operator[](0);
    }

    function stake(address assetAddress, uint256 amount) public returns (bool) {
        return false;
    }

    function unstake(address assetAddress, uint256 amount)
        public
        returns (bool)
    {
        return false;
    }

    function pendingBalanceOf(address operator) public view returns (bool) {
        return false;
    }

    function withdraw(uint256 amount) public returns (bool) {
        return false;
    }

    function delegators() public view returns (address[] memory) {
        return new address[](0);
    }

    function isDelegator(address account) public view returns (bool) {
        return false;
    }

    function addDelegator(address account) public onlyOwner returns (bool) {
        return false;
    }

    function removeDelegator(address account) public onlyOwner returns (bool) {
        return false;
    }

    function slash(address operator) public onlyDelegator returns (bool) {
        return false;
    }
}
