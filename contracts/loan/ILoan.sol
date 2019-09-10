pragma solidity 0.5.8;

interface ILoan {
    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount
    ) external returns (uint256);
    function repay(uint256 recordId, uint256 amount) external returns (bool);
    function supplyCollateral(uint256 recordId, uint256 amount)
        external
        returns (bool);
    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount
    ) public returns (bool);
}
