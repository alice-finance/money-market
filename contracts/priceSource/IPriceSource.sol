pragma solidity ^0.5.11;

/**
 * @title IPriceSource
 * @notice Interface of PriceSource
 */
interface IPriceSource {
    event PriceReported(
        address indexed asset,
        address indexed reporter,
        uint256 indexed timeslot,
        uint256 price
    );

    event PriceAccepted(
        address indexed asset,
        address indexed reporter,
        uint256 indexed timeslot,
        uint256 price
    );

    /**
     * @notice get valid price of given asset by USD in given timeslot
     * @param asset address of the asset
     * @param timeslot timeslot to get price
     * @return uint256 asset price by USD. Multiplied by 10^18
     */
    function getPrice(address asset, uint256 timeslot)
        external
        view
        returns (uint256);

    /**
     * @notice get last valid price of given asset by USD
     * @param asset address of the asset
     * @return uint256 asset price by USD. Multiplied by 10^18
     */
    function getLastPrice(address asset) external view returns (uint256);
}
