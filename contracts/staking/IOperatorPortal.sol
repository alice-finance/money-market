pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IOperatorPortal {
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

    function minimumStakingAmount() external view returns (uint256);

    function setMinimumStakingAmount(uint256 amount) external;

    function pendingRemovalDuration() external view returns (uint256);

    function setPendingWithdrawalDuration(uint256 duration) external;

    function totalStakeOf(address asset) external view returns (uint256);

    function stakeOf(address asset, address operator)
        external
        view
        returns (uint256);

    function balanceOf(address asset, address account)
        external
        view
        returns (uint256);

    function totalStakedAmount() external view returns (uint256);

    function getOperatorAssets(address operator)
        external
        view
        returns (address[] memory);

    function getAssetOperators(address asset)
        external
        view
        returns (address[] memory);

    function getAssetStakeholders(address asset)
        external
        view
        returns (address[] memory);

    function getAssetInfo(address asset)
        external
        view
        returns (AssetInfo memory);

    function getAllAssetInfo() external view returns (AssetInfo[] memory);

    function getOperatorInfo(address asset, address operator)
        external
        view
        returns (OperatorInfo memory);

    function getAllOperatorInfo(address asset)
        external
        view
        returns (OperatorInfo[] memory);

    function isOperator(address asset, address account)
        external
        view
        returns (bool);

    function isStakeholder(address asset, address account)
        external
        view
        returns (bool);

    function addStake(address asset, uint256 amount) external returns (bool);

    function removeStake(address asset, uint256 amount)
        external
        returns (uint256);

    function pendingBalanceOf(address operator, uint256 removalId)
        external
        view
        returns (uint256);

    function pendingRemovalListOf(address operator)
        external
        view
        returns (PendingWithdrawal[] memory);

    function withdrawableBalanceOf(address account, uint256 removalId)
        external
        view
        returns (uint256);

    function withdraw(uint256 amount, uint256 removalId)
        external
        returns (bool);

    function isDelegator(address account) external view returns (bool);

    function addDelegator(address account) external returns (bool);

    function removeDelegator(address account) external returns (bool);

    function slash(address asset, address operator, uint256 amount)
        external
        returns (bool);

    function batchSlash(
        address asset,
        address[] calldata operatorList,
        uint256[] calldata amountList
    ) external returns (bool);
}
