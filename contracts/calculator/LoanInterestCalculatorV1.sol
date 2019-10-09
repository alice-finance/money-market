pragma solidity ^0.5.11;

import "./ILoanInterestCalculator.sol";
import "./BaseInterestCalculator.sol";

contract LoanInterestCalculatorV1 is
    BaseInterestCalculator,
    ILoanInterestCalculator
{
    uint256 public constant A = 99363990000000;
    uint256 public constant C = 210000000000000;

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
