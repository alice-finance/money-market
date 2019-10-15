pragma solidity ^0.5.11;

import "../staking/IDelegator.sol";
import "../staking/IOperatorPortal.sol";

contract DelegatorMock is IDelegator {
    bool private _isDelegator = true;
    mapping(address => mapping(address => bool)) private _removable;
    IOperatorPortal portal;

    function setPortal(IOperatorPortal newPortal) public {
        portal = newPortal;
    }

    function isDelegator() public view returns (bool) {
        return _isDelegator;
    }

    function isStakeRemovable(address asset, address operator)
        public
        view
        returns (bool)
    {
        return _removable[asset][operator];
    }

    function setStakeRemovable(address asset, address operator, bool removable)
        public
    {
        _removable[asset][operator] = removable;
    }

    function slash(address asset, address operator, uint256 amount) public {
        portal.slash(asset, operator, amount);
    }

    function batchSlash(
        address asset,
        address[] memory operatorList,
        uint256[] memory amountList
    ) public {
        portal.batchSlash(asset, operatorList, amountList);
    }
}
