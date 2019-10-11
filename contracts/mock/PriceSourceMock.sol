pragma solidity ^0.5.11;

import "../priceSource/IPriceSource.sol";

contract PriceSourceMock is IPriceSource {
    mapping(address => uint256) private _price;

    function setPrice(address asset, uint256 price) public {
        _price[asset] = price;
    }

    function getPrice(address asset, uint256 timeslot)
        public
        view
        returns (uint256)
    {
        timeslot;
        return _price[asset];
    }

    function getLastPrice(address asset) public view returns (uint256) {
        return _price[asset];
    }
}
