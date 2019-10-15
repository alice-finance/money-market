pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "../staking/IOperatorPortal.sol";

contract OperatorPortalMock is IOperatorPortal {
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
}
