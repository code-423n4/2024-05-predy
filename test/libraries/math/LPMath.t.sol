// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "../../../src/libraries/math/LPMath.sol";
import "../../../src/libraries/Constants.sol";

contract LPMathTest is Test {
    function testCalculateAmount0ForLiquidity(uint256 _sqrtPriceA, uint256 _sqrtPriceB, uint256 _liquidityAmount)
        public
    {
        uint160 sqrtPriceA = uint160(bound(_sqrtPriceA, Constants.MIN_SQRT_PRICE, Constants.MAX_SQRT_PRICE));
        uint160 sqrtPriceB = uint160(bound(_sqrtPriceB, sqrtPriceA, Constants.MAX_SQRT_PRICE));
        uint128 liquidityAmount = uint128(bound(_liquidityAmount, 0, 1e36));

        uint256 expectedAmount0 = LiquidityAmounts.getAmount0ForLiquidity(sqrtPriceA, sqrtPriceB, liquidityAmount);

        int256 amount0RoundDown = LPMath.calculateAmount0ForLiquidity(sqrtPriceA, sqrtPriceB, liquidityAmount, false);
        int256 amount0RoundUp = LPMath.calculateAmount0ForLiquidity(sqrtPriceA, sqrtPriceB, liquidityAmount, true);

        assertLe(amount0RoundDown, int256(expectedAmount0));
        assertGe(amount0RoundUp, int256(expectedAmount0));
    }

    function testCalculateAmount1ForLiquidity(uint256 _sqrtPriceA, uint256 _sqrtPriceB, uint256 _liquidityAmount)
        public
    {
        uint160 sqrtPriceA = uint160(bound(_sqrtPriceA, Constants.MIN_SQRT_PRICE, Constants.MAX_SQRT_PRICE));
        uint160 sqrtPriceB = uint160(bound(_sqrtPriceB, sqrtPriceA, Constants.MAX_SQRT_PRICE));
        uint128 liquidityAmount = uint128(bound(_liquidityAmount, 0, 1e36));

        uint256 expectedAmount1 = LiquidityAmounts.getAmount1ForLiquidity(sqrtPriceB, sqrtPriceA, liquidityAmount);

        int256 amount1RoundDown = LPMath.calculateAmount1ForLiquidity(sqrtPriceB, sqrtPriceA, liquidityAmount, false);
        int256 amount1RoundUp = LPMath.calculateAmount1ForLiquidity(sqrtPriceB, sqrtPriceA, liquidityAmount, true);

        assertLe(amount1RoundDown, int256(expectedAmount1));
        assertGe(amount1RoundUp, int256(expectedAmount1));
    }
}
