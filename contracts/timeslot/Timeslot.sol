pragma solidity ^0.5.11;

contract Timeslot {
    uint256 constant PRICE_FEED_INTERVAL = 600; // 10 minutes

    function timestampToTimeslot(uint256 timestamp)
        public
        pure
        returns (uint256)
    {
        return timestamp - (timestamp % PRICE_FEED_INTERVAL);
    }

    function previousTimeslot(uint256 timeslot) public pure returns (uint256) {
        return timeslot - PRICE_FEED_INTERVAL;
    }

    function nextTimeslot(uint256 timeslot) public pure returns (uint256) {
        return timeslot + PRICE_FEED_INTERVAL;
    }

    function isTimeslot(uint256 timeslot) public pure returns (bool) {
        return timeslot % PRICE_FEED_INTERVAL == 0;
    }
}
