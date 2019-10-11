pragma solidity ^0.5.11;

pragma experimental ABIEncoderV2;

interface IExchangePriceSource {
    struct Price {
        uint256 ask;
        uint256 bid;
    }

    function getPriceAt(
        address askAssetAddress,
        address bidAssetAddress,
        uint256 timeslot
    ) external view returns (Price memory);
}

contract ExchangeMock is IExchangePriceSource {
    mapping(address => uint256) prices;
    function setPrice(address asset, uint256 price) public {
        prices[asset] = price;
    }
    function getPriceAt(
        address askAssetAddress,
        address bidAssetAddress,
        uint256 timeslot
    ) public view returns (Price memory) {
        bidAssetAddress;
        timeslot;
        return Price(prices[askAssetAddress], 10**18);
    }
}
