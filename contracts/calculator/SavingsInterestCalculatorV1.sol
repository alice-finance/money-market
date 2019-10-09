pragma solidity ^0.5.11;

import "./BaseInterestCalculator.sol";

contract SavingsInterestCalculatorV1 is BaseInterestCalculator {
    struct CalculationParams {
        int256 CM;
        int256 CMAX;
        int256 X;
        int256 V;
        int256 A;
        int256 PI;
    }

    function getInterestRate(
        uint256 totalSavings,
        uint256, /* totalBorrows */
        uint256 amount
    ) public pure returns (uint256) {
        /**
        Algorithm

        Requirements
        1. Need cosine-approximated graph in range of x from 0 to 2000000000. x has decimal 18
        2. Need output from 8.0 to 0.0
        3. When x > 2000000000, output should be 0

        Algorithm
        1. cos(x) = cos(-x),
        2. 4(cos(x/2000000000/pi) + 1) converts cosine graph to x range 0 to 20000000000, y range 8 to 0
        3. cos(x) is approximated by a polynomial of degree 14 (by Taylor Series) and is accurate enough to use it.
            cos(x) ~ 1 - (x^2/2!) + (x^4/4!) - (x^6/6!) + (x^8/8!) - (x^10/10!) + (x^12/12!) - (x^14/14!) + ....
        4. 4(cos(x/2000000000/pi) + 1) is approximated into
            ~ 1 - (x/2000000000/pi)^2/2! + (x/2000000000/pi)^4/4! + ....

            We can pre-calculate 2000000000/pi, 2!, 4!, ...
        5. Solidity doesn't have floating point number type, so we use MULTIPLIER to calculate value.
        6. Only need uint values.
        */
        CalculationParams memory params = CalculationParams(
            10 ** 18,
            0,
            0,
            0,
            0,
            3141592653589793238
        );
        params.CMAX = 2000000 * params.CM;
        params.X = int256(totalSavings);
        params.V = int256(amount);
        params.A = params.V / 2;

        // return 0 when overflowed
        if (params.X < 0) return 0;
        // return 0 when totalSavings over MAX
        if (params.X >= params.CMAX) return 0;
        if (params.X + params.A >= params.CMAX) return 0;

        params.X += params.A;

        int256 v = (params.X * params.PI) / params.CMAX;
        int256 z = v * v / params.CM;
        int256 r = params.CM - z / 2 + z * z / params.CM / 24 - z * z / params.CM * z / params.CM / 720 + z * z / params.CM * z / params.CM * z / params.CM / 40320 - z * z / params.CM * z / params.CM * z / params.CM * z / params.CM / 3628800 + z * z / params.CM * z / params.CM * z / params.CM * z / params.CM * z / params.CM / 479001600 - z * z / params.CM * z / params.CM * z / params.CM * z / params.CM * z / params.CM * z / params.CM / 87178291200;

        // MAX Rate is approximately yearly 8%
        // Convert result range into Daily interest rate
        // root 365 (1.08) ~ 1.000210874398376755 ~ 1.0002
        // 1.0002 ^ 365 ~ 1.079999999999919314 ~ 1.08
        // add and sub (-439442122) to make result always positive number
        r = ((r + params.CM) * (210874398376755 + - 439442122)) / (2 * params.CM) - (- 439442122);

        // return ZERO if calculated rate is negative value
        // pretty sure this will not happen, but safety first :(
        if (r < 0) return 0;

        return uint256(r);
    }
}
