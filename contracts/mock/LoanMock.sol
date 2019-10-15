pragma solidity ^0.5.11;

import "../loan/ILoan.sol";
import "../base/Constants.sol";
pragma experimental ABIEncoderV2;

contract LoanMock is ILoan, Constants {
    function borrow(
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        bytes memory data
    ) public returns (uint256) {
        amount;
        collateral;
        collateralAmount;
        data;
        revert("not implemented");
    }

    function repay(uint256 recordId, uint256 amount, bytes memory data)
        public
        returns (bool)
    {
        recordId;
        amount;
        data;
        revert("not implemented");
    }

    function supplyCollateral(
        uint256 recordId,
        uint256 amount,
        bytes memory data
    ) public returns (bool) {
        recordId;
        amount;
        data;
        revert("not implemented");
    }

    function liquidate(
        uint256 recordId,
        uint256 amount,
        uint256 collateralAmount,
        bytes memory data
    ) public returns (bool) {
        recordId;
        amount;
        collateralAmount;
        data;

        emit LoanLiquidated(
            recordId,
            address(0),
            address(0),
            amount,
            0,
            address(0),
            collateralAmount,
            block.timestamp
        );
        return true;
    }

    function getActiveLoanRecordsWithData(bytes memory data)
        public
        view
        returns (LoanRecord[] memory)
    {
        data;
        revert("not implemented");
    }

    function totalBorrows() public view returns (uint256) {
        return _totalBorrow;
    }

    function totalBorrowsByCollateral(address collateral)
        public
        view
        returns (uint256)
    {
        return _totalBorrowWithCollateral[collateral];
    }

    function getActiveLoanRecordsByCollateralWithData(
        address collateral,
        uint256 minCollateralRate,
        uint256 maxCollateralRate,
        bytes memory data
    ) public view returns (LoanRecord[] memory) {
        collateral;
        minCollateralRate;
        maxCollateralRate;
        data;
        revert("not implemented");
    }

    mapping(address => LoanRecord[]) private _loans;
    mapping(address => uint256) private _totalBorrowWithCollateral;
    uint256 private _totalBorrow = 0;
    uint256 private _totalCollateral = 0;

    function addLoan(
        uint256 amount,
        address collateral,
        uint256 collateralAmount,
        address owner
    ) public {
        uint256 id = _loans[collateral].length;
        _loans[collateral].length += 1;

        _loans[collateral][id].id = id;
        _loans[collateral][id].owner = owner;
        _loans[collateral][id].interestIndex = MULTIPLIER;
        _loans[collateral][id].balance = amount;
        _loans[collateral][id].principal = amount;
        _loans[collateral][id].collateral = collateral;
        _loans[collateral][id].collateralAmount = collateralAmount;
        _loans[collateral][id].collateralRate = MULTIPLIER;
        _loans[collateral][id].initialTimestamp = block.timestamp;
        _loans[collateral][id].lastTimestamp = block.timestamp;

        _totalBorrow += amount;
        _totalBorrowWithCollateral[collateral] += collateralAmount;
    }

    function getLoanRecordsOnDefaultWithData(bytes memory data)
        public
        view
        returns (LoanRecord[] memory)
    {
        (, bytes memory extractedData) = _extractData(data);
        address asset = _extractAddress(extractedData);

        return _loans[asset];
    }

    function _extractData(bytes memory data)
        internal
        pure
        returns (uint8, bytes memory)
    {
        uint8 dataType = data.length > 0 ? uint8(data[0]) : 0;
        bytes memory resultData = new bytes(data.length);
        for (uint256 i = 1; i < data.length; i++) {
            resultData[i - 1] = data[i];
        }
        return (dataType, resultData);
    }

    function _extractAddress(bytes memory data)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
