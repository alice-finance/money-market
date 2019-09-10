pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract PriceManager {
    uint8 constant PRICE_FEED_INTERVAL = 10 minutes;

    struct PriceData {
        address asset;
        address reporter;
        uint256 price;
        uint256 timestamp;
    }

    PriceData[] private _priceDataList;

    // asset => timeSlot => price
    mapping(address => mapping(uint256 => uint256)) private _priceFeed;
    // asset => timeSlot => priceData
    mapping(address => mapping(uint256 => uint256[])) private _priceData;
    // operator => timeSlot
    mapping(address => uint256) private _lastReportedSlot;

    function getCurrentPrice(address asset) public returns (uint256) {
        return _getPriceAtSlot(asset, _timestampToSlot(block.timestamp));
    }

    function getPriceAt(address asset, uint256 timestamp)
        public
        returns (uint256)
    {
        return _getPriceAtSlot(asset, _timestampToSlot(timestamp));
    }

    function reportPrice(address asset, uint256 price, uint256 timestamp)
        public
        returns (bool)
    {
        uint256 slot = _timestampToSlot(timestamp);
        uint256 dataId = _priceDataList.length;
        _priceDataList.length += 1;

        _priceDataList[dataId].asset = asset;
        _priceDataList[dataId].reporter = msg.sender;
        _priceDataList[dataId].price = price;
        _priceDataList[dataId].timestamp = timestamp;

        _priceData[asset][slot].push(dataId);

        if (_lastReportedSlot[msg.sender] < slot) {
            _lastReportedSlot[msg.sender] = slot;
        }

        return false;
    }

    function validatePrice() public returns (bool) {
        // Collect price data into price _price feed

        // penalize operators who did not reported price data

        // penalize operators if defaulted loan was not liquidated

        return false;
    }

    function _getPriceAtSlot(address asset, uint256 slot)
        internal
        view
        returns (uint256)
    {
        return _priceFeed[asset][slot];
    }

    function _timestampToSlot(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return timestamp - (timestamp % PRICE_FEED_INTERVAL);
    }
}
