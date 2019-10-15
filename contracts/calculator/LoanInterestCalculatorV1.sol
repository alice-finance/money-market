pragma solidity ^0.5.11;

import "./ILoanInterestCalculator.sol";
import "./BaseInterestCalculator.sol";

contract LoanInterestCalculatorV1 is
    ILoanInterestCalculator,
    BaseInterestCalculator
{
    uint256 public constant A = 99363990000000;
    uint256 public constant C = 210000000000000;

    function calculateIndex(
        uint256 previousIndex,
        uint256 rate,
        uint256 timeDiff
    ) public pure returns (uint256) {
        uint256 diff = (timeDiff * MULTIPLIER) / 86400;
        uint256 d = diff / MULTIPLIER;
        uint256 h = diff % MULTIPLIER;
        uint256 newIndex = previousIndex;

        for (uint256 i = 0; i < d; i++) {
            newIndex = (newIndex * (MULTIPLIER + rate)) / MULTIPLIER;
        }

        if (h > 0) {
            newIndex =
                (newIndex * ((rate * h) / MULTIPLIER + MULTIPLIER)) /
                MULTIPLIER;
        }

        return newIndex;
    }

    function getExpectedBalanceWithIndex(
        uint256 principal,
        uint256 fromIndex,
        uint256 toIndex
    ) public pure returns (uint256) {
        return (principal * toIndex) / fromIndex;
    }

    function getInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 totalRemains = totalSavings - totalBorrows;
        if (totalRemains == 0) {
            return uint256(-1);
        }
        uint256 r = C + ((totalBorrows * A) / totalRemains);

        return r;
    }

    struct CalculationParams {
        uint256 sumOfValues;
        uint256 averageOfValues;
        uint256 sumOfBases;
        uint256 targetBase;
        uint256 rate;
    }

    function getCollateralInterestRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256[] memory collateralValues,
        uint256 index,
        uint256 amount
    ) public pure returns (uint256) {
        CalculationParams memory params = CalculationParams(0, 0, 0, 0, 0);

        for (uint256 i = 0; i < collateralValues.length; i++) {
            params.sumOfValues += collateralValues[i];
        }

        params.averageOfValues = params.sumOfValues / collateralValues.length;

        params.rate = getInterestRate(totalSavings, totalBorrows, amount);

        for (uint256 j = 0; j < collateralValues.length; j++) {
            uint256 base = getCollateralBaseInterestRate(
                params.rate,
                params.sumOfValues,
                params.averageOfValues,
                collateralValues[j]
            );
            params.sumOfBases += base;
            if (j == index) {
                params.targetBase = base;
            }
        }

        return
            (((params.sumOfValues * params.rate) / params.sumOfBases) *
                    params.targetBase) /
                MULTIPLIER;
    }

    function getInterestShareRate(
        uint256 totalSavings,
        uint256 totalBorrows,
        uint256 loanInterestRate,
        uint256 amount
    ) public pure returns (uint256) {
        // TODO: need to implement this
        return 50000000000000000; // 0.05
    }

    struct BaseCalculationParams {
        uint256 part1;
        uint256 part2;
        uint256 part3;
        uint256 part4;
    }

    function getCollateralBaseInterestRate(
        uint256 rate,
        uint256 sum,
        uint256 avg,
        uint256 amount
    ) internal pure returns (uint256) {
        BaseCalculationParams memory params = BaseCalculationParams(0, 0, 0, 0);
        params.part1 = ((amount * MULTIPLIER) / (sum - amount));
        params.part2 = ((amount - avg) * rate) / MULTIPLIER;
        params.part3 = rate + (params.part1 * params.part2) / avg;
        params.part4 = (amount * MULTIPLIER) / avg;

        return (params.part3 * params.part4) / MULTIPLIER;
    }
}
