pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";

contract OperatorPortal is Ownable {
    struct Asset {
        address assetAddress;
        uint256 operatorStakedAmount;
        uint256 totalStakedAmount;
    }

    struct Operator {
        address operatorAddress;
        uint256 operatorStakedAmount;
        uint256 totalStakedAmount;
    }

    struct PendingWithdrawal {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 startsAt;
        uint256 endsAt;
    }

    mapping(address => bool) internal _delegatorList;

    uint256 internal _unstakingPeriod;
    uint256 internal _minimumStakingAmount;

    // operator => asset => amount
    mapping(address => mapping(address => uint256)) internal _operatorAssetStakedAmount;
    // asset => amount
    mapping(address => uint256) internal _assetStakedAmount;
    // operator => amount
    mapping(address => uint256) internal _operatorStakedAmount;

    // operator => asset[]
    mapping(address => address[]) internal _assetsOf;
    // asset => operator[]
    mapping(address => address[]) internal _operatorsOf;

    address[] internal _assets;
    address[] internal _operators;

    uint256 internal _totalStakedAmount;

    event DelegatorAdded(address indexed account, uint256 timestamp);
    event DelegatorRemoved(address indexed account, uint256 timestamp);

    event MinimumStakingAmountChanged(uint256 from, uint256 to);
    event UnstakingPeriodChanged(uint256 from, uint256 to);

    modifier onlyDelegator {
        require(isDelegator(msg.sender) == true, "caller is not delegator");
        _;
    }

    constructor(address ownerAddress) public {
        _owner = ownerAddress;
    }

    function minimumStakingAmount() public view returns (uint256) {
        return _minimumStakingAmount;
    }

    function setMinimumStakingAmount(uint256 amount) public onlyOwner {
        emit MinimumStakingAmountChanged(_minimumStakingAmount, amount);

        _minimumStakingAmount = amount;
    }

    function unstakingPeriod() public view returns (uint256) {
        return _unstakingPeriod;
    }

    function setUnstakingPeriod(uint256 period) public onlyOwner {
        emit UnstakingPeriodChanged(_unstakingPeriod, period);

        _unstakingPeriod = period;
    }

    function assets() public view returns (Asset[] memory) {
        Asset[] memory assets = new Asset[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            assets[i] = Asset(_assets[i], 0, _assetStakedAmount[_assets[i]]);
        }

        return assets;
    }

    function asset(address assetAddress) public view returns (Asset memory) {
        return Asset(assetAddress, 0, _assetStakedAmount[assetAddress]);
    }

    function totalStakedAmount() public view returns (uint256) {
        return _totalStakedAmount;
    }

    function assetsOf(address operator) public view returns (Asset[] memory) {
        Asset[] memory assetList = new Asset[](_assetsOf[operator].length);

        for (uint256 i = 0; i < _assetsOf[operator].length; i++) {
            address asset = _assetsOf[operator][i];
            assetList[i] = Asset(
                asset,
                _operatorAssetStakedAmount[operator][asset],
                _assetStakedAmount[asset]
            );
        }

        return assetList;
    }

    function operatorsOf(address assetAddress)
        public
        view
        returns (Operator[] memory)
    {
        Operator[] memory operatorList = new Operator[](
            _operatorsOf[assetAddress].length
        );

        for (uint256 i = 0; i < _operatorsOf[assetAddress].length; i++) {
            address operator = _operatorsOf[assetAddress][i];
            operatorList[i] = Operator(
                operator,
                _operatorAssetStakedAmount[operator][assetAddress],
                _operatorStakedAmount[operator]
            );
        }

        return operatorList;
    }

    function isOperator(address account, address assetAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _operatorsOf[assetAddress].length; i++) {
            if (account == _operatorsOf[assetAddress][i]) {
                return true;
            }
        }

        return false;
    }

    function stake(address assetAddress, uint256 amount) public returns (bool) {
        require(
            amount >= _minimumStakingAmount,
            "less than minimum staking amount"
        );

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

    function isDelegator(address account) public view returns (bool) {
        return _delegatorList[account];
    }

    function addDelegator(address account) public onlyOwner returns (bool) {
        require(account != address(0), "ZERO address");

        _delegatorList[account] = true;

        emit DelegatorAdded(account, block.timestamp);

        return true;
    }

    function removeDelegator(address account) public onlyOwner returns (bool) {
        require(_delegatorList[account], "account is not delegator");

        _delegatorList[account] = false;

        emit DelegatorRemoved(account, block.timestamp);

        return true;
    }

    function slash(address operator) public onlyDelegator returns (bool) {
        return false;
    }
}
