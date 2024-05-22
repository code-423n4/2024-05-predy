// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library LPMath {
    function calculateAmount0ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return calculateAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickA), TickMath.getSqrtRatioAtTick(tickB), liquidityAmount, isRoundUp
        );
    }

    function calculateAmount1ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return calculateAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickA), TickMath.getSqrtRatioAtTick(tickB), liquidityAmount, isRoundUp
        );
    }

    function calculateAmount0ForLiquidity(
        uint160 sqrtRatioA,
        uint160 sqrtRatioB,
        uint256 liquidityAmount,
        bool isRoundUp
    ) internal pure returns (int256) {
        if (liquidityAmount == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        bool swaped = sqrtRatioA > sqrtRatioB;

        if (sqrtRatioA > sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

        int256 r;

        bool _isRoundUp = swaped ? !isRoundUp : isRoundUp;
        uint256 numerator = liquidityAmount;

        if (_isRoundUp) {
            uint256 r0 = FullMath.mulDivRoundingUp(numerator, FixedPoint96.Q96, sqrtRatioA);
            uint256 r1 = FullMath.mulDiv(numerator, FixedPoint96.Q96, sqrtRatioB);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 = FullMath.mulDiv(numerator, FixedPoint96.Q96, sqrtRatioA);
            uint256 r1 = FullMath.mulDivRoundingUp(numerator, FixedPoint96.Q96, sqrtRatioB);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    function calculateAmount1ForLiquidity(
        uint160 sqrtRatioA,
        uint160 sqrtRatioB,
        uint256 liquidityAmount,
        bool isRoundUp
    ) internal pure returns (int256) {
        if (liquidityAmount == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        bool swaped = sqrtRatioA < sqrtRatioB;

        if (sqrtRatioA < sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

        int256 r;

        bool _isRoundUp = swaped ? !isRoundUp : isRoundUp;

        if (_isRoundUp) {
            uint256 r0 = FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDiv(liquidityAmount, sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 = FullMath.mulDiv(liquidityAmount, sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    /**
     * @notice Calculates L / (1.0001)^(b/2)
     */
    function calculateAmount0OffsetWithTick(int24 upper, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return SafeCast.toInt256(calculateAmount0Offset(TickMath.getSqrtRatioAtTick(upper), liquidityAmount, isRoundUp));
    }

    /**
     * @notice Calculates L / sqrt{p_b}
     */
    function calculateAmount0Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (isRoundUp) {
            return FullMath.mulDivRoundingUp(liquidityAmount, FixedPoint96.Q96, sqrtRatio);
        } else {
            return FullMath.mulDiv(liquidityAmount, FixedPoint96.Q96, sqrtRatio);
        }
    }

    /**
     * @notice Calculates L * (1.0001)^(a/2)
     */
    function calculateAmount1OffsetWithTick(int24 lower, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return SafeCast.toInt256(calculateAmount1Offset(TickMath.getSqrtRatioAtTick(lower), liquidityAmount, isRoundUp));
    }

    /**
     * @notice Calculates L * sqrt{p_a}
     */
    function calculateAmount1Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (isRoundUp) {
            return FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatio, FixedPoint96.Q96);
        } else {
            return FullMath.mulDiv(liquidityAmount, sqrtRatio, FixedPoint96.Q96);
        }
    }
}
