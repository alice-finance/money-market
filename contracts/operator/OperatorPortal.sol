pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IDelegator.sol";
import "../Ownable.sol";

contract OperatorPortal is Ownable {
    struct AssetInfo {
        address asset;
        uint256 numOperator;
        uint256 totalStakedAmount;
    }

    struct OperatorInfo {
        address operator;
        uint256 stakedAmount;
    }

    struct PendingWithdrawal {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 startsAt;
        uint256 endsAt;
    }

    IDelegator[] internal _delegatorList;
    IERC20 internal _alice;

    uint256 internal _pendingRemovalDuration;
    uint256 internal _minimumStakingAmount;

    // asset => amount
    mapping(address => uint256) internal _assetStake;
    // asset => operator => amount
    mapping(address => mapping(address => uint256)) internal _accountStake;

    // operator => asset[]
    mapping(address => address[]) internal _stakeholderAssets;

    // asset => operator[]
    mapping(address => address[]) internal _assetOperators;
    mapping(address => address[]) internal _assetStakeholders;

    // operator => PendingWithdrawal
    mapping(address => PendingWithdrawal[]) internal _pendingRemovalList;

    address[] internal _assets;
    mapping(address => bool) internal _isAsset;

    mapping(address => uint256) internal _totalOperatorBalance;
    mapping(address => uint256) internal _totalAccountStake;

    uint256 internal _totalStakedAmount;
    uint256 internal _totalSlashed;

    event AssetAdded(address indexed asset, uint256 timestamp);

    event StakeholderAdded(
        address indexed asset,
        address indexed account,
        uint256 timestamp
    );

    event StakeholderRemoved(
        address indexed asset,
        address indexed account,
        uint256 timestamp
    );

    event OperatorAdded(
        address indexed asset,
        address indexed account,
        uint256 timestamp
    );

    event OperatorRemoved(
        address indexed asset,
        address indexed account,
        uint256 timestamp
    );

    event StakeAdded(
        address indexed asset,
        address indexed account,
        uint256 amount,
        uint256 stakeAmount,
        uint256 timestamp
    );
    event StakeRemoved(
        address indexed asset,
        address indexed account,
        bool indexed slashed,
        uint256 amount,
        uint256 stakeAmount,
        uint256 timestamp
    );
    event RemovalRecordCreated(
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event Withdrawn(
        uint256 indexed id,
        address indexed account,
        uint256 amount,
        uint256 totalAmount,
        uint256 remainingAmount,
        uint256 timestamp
    );

    event DelegatorAdded(address indexed account, uint256 timestamp);
    event DelegatorRemoved(address indexed account, uint256 timestamp);

    event MinimumStakingAmountChanged(uint256 from, uint256 to);
    event PendingRemovalDurationChanged(uint256 from, uint256 to);

    modifier onlyDelegator {
        require(isDelegator(msg.sender) == true, "caller is not delegator");
        _;
    }

    constructor(
        address ownerAddress,
        address aliceAddress,
        uint256 minimumStakingAmount
    ) public {
        _owner = ownerAddress;
        _alice = IERC20(aliceAddress);
        _minimumStakingAmount = minimumStakingAmount;
        _pendingRemovalDuration = 604800;
    }

    function minimumStakingAmount() public view returns (uint256) {
        return _minimumStakingAmount;
    }

    function setMinimumStakingAmount(uint256 amount) public onlyOwner {
        emit MinimumStakingAmountChanged(_minimumStakingAmount, amount);

        _minimumStakingAmount = amount;
    }

    function pendingRemovalDuration() public view returns (uint256) {
        return _pendingRemovalDuration;
    }

    function setPendingWithdrawalDuration(uint256 duration) public onlyOwner {
        require(duration >= 3600, "duration is less than a day");
        emit PendingRemovalDurationChanged(_pendingRemovalDuration, duration);

        _pendingRemovalDuration = duration;
    }

    function totalStakeOf(address asset) public view returns (uint256) {
        return _assetStake[asset];
    }

    function stakeOf(address asset, address operator)
        public
        view
        returns (uint256)
    {
        return _accountStake[asset][operator];
    }

    function balanceOf(address asset, address account)
        public
        view
        returns (uint256)
    {
        return _accountStake[asset][account];
    }

    function totalStakedAmount() public view returns (uint256) {
        return _totalStakedAmount;
    }

    function getOperatorAssets(address operator)
        public
        view
        returns (address[] memory)
    {
        return _stakeholderAssets[operator];
    }

    function getAssetOperators(address asset)
        public
        view
        returns (address[] memory)
    {
        return _assetOperators[asset];
    }

    function getAssetStakeholders(address asset)
        public
        view
        returns (address[] memory)
    {
        return _assetStakeholders[asset];
    }

    function getAssetInfo(address asset)
        public
        view
        returns (AssetInfo memory)
    {
        return
            AssetInfo(asset, _assetOperators[asset].length, _assetStake[asset]);
    }

    function getAllAssetInfo() public view returns (AssetInfo[] memory) {
        AssetInfo[] memory assetList = new AssetInfo[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            assetList[i] = getAssetInfo(_assets[i]);
        }

        return assetList;
    }

    function getOperatorInfo(address asset, address operator)
        public
        view
        returns (OperatorInfo memory)
    {
        return OperatorInfo(operator, _accountStake[asset][operator]);
    }

    function getAllOperatorInfo(address asset)
        public
        view
        returns (OperatorInfo[] memory)
    {
        OperatorInfo[] memory operatorList = new OperatorInfo[](
            _assetOperators[asset].length
        );

        for (uint256 i = 0; i < _assetOperators[asset].length; i++) {
            operatorList[i] = getOperatorInfo(asset, _assetOperators[asset][i]);
        }

        return operatorList;
    }

    function isOperator(address asset, address account)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _assetOperators[asset].length; i++) {
            if (account == _assetOperators[asset][i]) {
                return true;
            }
        }

        return false;
    }

    function isStakeholder(address asset, address account)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _assetStakeholders[asset].length; i++) {
            if (account == _assetStakeholders[asset][i]) {
                return true;
            }
        }

        return false;
    }

    function addStake(address asset, uint256 amount) public returns (bool) {
        bool alreadyStakeholder = isStakeholder(asset, msg.sender);
        bool alreadyOperator = isOperator(asset, msg.sender);

        if (!alreadyOperator) {
            require(
                amount >= _minimumStakingAmount,
                "less than minimum staking amount"
            );
        }

        require(
            _alice.allowance(msg.sender, address(this)) >= amount,
            "allowance not met"
        );

        _assetStake[asset] += amount;
        _accountStake[asset][msg.sender] += amount;
        _totalAccountStake[msg.sender] += amount;
        if (!alreadyStakeholder) {
            _assetStakeholders[asset].push(msg.sender);

            emit StakeholderAdded(asset, msg.sender, block.timestamp);
        }

        if (!alreadyOperator) {
            _assetOperators[asset].push(msg.sender);

            emit OperatorAdded(asset, msg.sender, block.timestamp);
        }

        if (!_isAsset[asset]) {
            _isAsset[asset] = true;
            _assets.push(asset);

            emit AssetAdded(asset, block.timestamp);
        }

        emit StakeAdded(
            asset,
            msg.sender,
            amount,
            _accountStake[asset][msg.sender],
            block.timestamp
        );

        require(
            _alice.transferFrom(msg.sender, address(this), amount),
            "cannot transfer alice"
        );

        return true;
    }

    function removeStake(address asset, uint256 amount)
        public
        returns (uint256)
    {
        require(_isAllStakeRemovable(asset, msg.sender), "not unstakable");
        require(
            _accountStake[asset][msg.sender] > amount,
            "not enough balance"
        );

        _accountStake[asset][msg.sender] -= amount;

        uint256 id = _pendingRemovalList[msg.sender].length;
        _pendingRemovalList[msg.sender].length += 1;
        _pendingRemovalList[msg.sender][id].totalAmount = amount;
        _pendingRemovalList[msg.sender][id].remainingAmount = amount;
        _pendingRemovalList[msg.sender][id].startsAt = block.timestamp;
        _pendingRemovalList[msg.sender][id].endsAt =
            block.timestamp +
            _pendingRemovalDuration;

        if (
            _accountStake[asset][msg.sender] < _minimumStakingAmount &&
            isOperator(asset, msg.sender)
        ) {
            _removeOperator(asset, msg.sender);
        }

        if (_accountStake[asset][msg.sender] == 0) {
            _removeStakeholder(asset, msg.sender);
        }

        emit StakeRemoved(
            asset,
            msg.sender,
            false,
            amount,
            _accountStake[asset][msg.sender],
            block.timestamp
        );

        emit RemovalRecordCreated(id, msg.sender, amount, block.timestamp);

        return id;
    }

    function pendingBalanceOf(address operator, uint256 removalId)
        public
        view
        returns (uint256)
    {
        return _pendingRemovalList[operator][removalId].remainingAmount;
    }

    function pendingRemovalListOf(address operator)
        public
        view
        returns (PendingWithdrawal[] memory)
    {
        return _pendingRemovalList[operator];
    }

    function withdrawableBalanceOf(address account, uint256 removalId)
        public
        view
        returns (uint256)
    {
        uint256 totalCount = _pendingRemovalDuration / 86400;
        // duration / 1 day
        uint256 currentCount = (block.timestamp -
                _pendingRemovalList[account][removalId].startsAt) /
            86400;
        // passed / 1 day
        uint256 eachAmount = _pendingRemovalList[account][removalId]
                .totalAmount /
            totalCount;
        uint256 withdrawnAmount = _pendingRemovalList[account][removalId]
                .totalAmount -
            _pendingRemovalList[account][removalId].remainingAmount;
        uint256 withdrawableAmount = eachAmount * currentCount;

        if (
            withdrawableAmount >
            _pendingRemovalList[account][removalId].totalAmount
        ) {
            withdrawableAmount = _pendingRemovalList[account][removalId]
                .totalAmount;
        }

        return withdrawableAmount - withdrawnAmount;
    }

    function withdraw(uint256 amount, uint256 removalId) public returns (bool) {
        require(amount <= withdrawableBalanceOf(msg.sender, removalId));

        _pendingRemovalList[msg.sender][removalId].remainingAmount -= amount;

        require(_alice.transfer(msg.sender, amount));

        emit Withdrawn(
            removalId,
            msg.sender,
            amount,
            _pendingRemovalList[msg.sender][removalId].totalAmount,
            _pendingRemovalList[msg.sender][removalId].remainingAmount,
            block.timestamp
        );
        return false;
    }

    function isDelegator(address account) public view returns (bool) {
        for (uint256 i = 0; i < _delegatorList.length; i++) {
            if (address(_delegatorList[i]) == account) {
                return true;
            }
        }

        return false;
    }

    function addDelegator(address account) public onlyOwner returns (bool) {
        require(account != address(0), "ZERO address");
        require(!isDelegator(account), "account is already delegator");
        require(IDelegator(account).isDelegator(), "account is not IDelegator");

        _delegatorList.push(IDelegator(account));

        emit DelegatorAdded(account, block.timestamp);

        return true;
    }

    function removeDelegator(address account) public onlyOwner returns (bool) {
        for (uint256 i = 0; i < _delegatorList.length; i++) {
            if (address(_delegatorList[i]) == account) {
                _delegatorList[i] = _delegatorList[_delegatorList.length - 1];
                _delegatorList.length -= 1;

                emit DelegatorRemoved(account, block.timestamp);

                return true;
            }
        }

        return false;
    }

    function slash(address asset, address operator, uint256 amount)
        public
        onlyDelegator
        returns (bool)
    {
        _slash(asset, operator, amount);
        _updateOperator(asset);
        return false;
    }

    function batchSlash(
        address asset,
        address[] memory operatorList,
        uint256[] memory amountList
    ) public onlyDelegator returns (bool) {
        require(operatorList.length == amountList.length);

        for (uint256 i = 0; i < operatorList.length; i++) {
            _slash(asset, operatorList[i], amountList[i]);
        }

        _updateOperator(asset);
        return false;
    }

    function _slash(address asset, address operator, uint256 amount) internal {
        _accountStake[asset][operator] -= amount;
        _assetStake[asset] -= amount;
        _totalSlashed += amount;

        emit StakeRemoved(
            asset,
            operator,
            true,
            amount,
            _accountStake[asset][operator],
            block.timestamp
        );
    }

    function _isAllStakeRemovable(address asset, address operator)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _delegatorList.length; i++) {
            if (!_delegatorList[i].isStakeRemovable(asset, operator)) {
                return false;
            }
        }

        return true;
    }

    function _removeOperator(address asset, address operator) internal {
        address[] storage operatorList = _assetOperators[asset];

        for (uint256 i = 0; i < operatorList.length; i++) {
            if (operatorList[i] == operator) {
                operatorList[i] = operatorList[operatorList.length - 1];
                operatorList.length -= 1;

                emit OperatorRemoved(asset, operator, block.timestamp);

                break;
            }
        }
    }

    function _updateOperator(address asset) internal {
        address[] storage operatorList = _assetOperators[asset];

        for (uint256 i = 0; i < operatorList.length; i++) {
            address operator = operatorList[i];

            if (_accountStake[asset][operator] < _minimumStakingAmount) {
                operatorList[i] = operatorList[operatorList.length - 1];
                operatorList.length -= 1;

                emit OperatorRemoved(asset, operator, block.timestamp);

                i -= 1;
            }
        }
    }

    function _removeStakeholder(address asset, address stakeholder) internal {
        address[] storage stakeholderList = _assetStakeholders[asset];

        for (uint256 i = 0; i < stakeholderList.length; i++) {
            if (stakeholderList[i] == stakeholder) {
                stakeholderList[i] = stakeholderList[stakeholderList.length -
                    1];
                stakeholderList.length -= 1;

                emit StakeholderRemoved(asset, stakeholder, block.timestamp);

                break;
            }
        }
    }

    function _updateStakeholder(address asset) internal {
        address[] storage stakeholderList = _assetStakeholders[asset];

        for (uint256 i = 0; i < stakeholderList.length; i++) {
            address stakeholder = stakeholderList[i];

            if (_accountStake[asset][stakeholder] == 0) {
                stakeholderList[i] = stakeholderList[stakeholderList.length -
                    1];
                stakeholderList.length -= 1;

                emit StakeholderRemoved(asset, stakeholder, block.timestamp);

                i -= 1;
            }
        }
    }
}
