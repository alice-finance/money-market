pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

import "./Constants.sol";

contract Ownable is Constants {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "not called from the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
