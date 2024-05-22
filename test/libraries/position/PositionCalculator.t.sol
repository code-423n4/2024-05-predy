// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/libraries/PositionCalculator.sol";

/*
 * https://www.desmos.com/calculator/p4gc1eri8v
 */
contract PositionCalculatorTest is Test {
    uint256 internal constant PRICE_ONE = 2 ** 96;
    uint256 internal constant MAX_AMOUNT = 1e36;
    uint256 internal constant RISK_RATIO = 109544511;

    function testCalculateValue() public {
        int256 value = PositionCalculator.calculateValue(0, PositionCalculator.PositionParams(0, 0, 0));

        assertEq(value, 0);
    }

    function testCalculateValuePriceOne() public {
        int256 value = PositionCalculator.calculateValue(PRICE_ONE, PositionCalculator.PositionParams(0, 0, 0));

        assertEq(value, 0);
    }

    function testCalculateValuePriceOne1(uint256 _stableAmount) public {
        int256 stableAmount = int256(bound(_stableAmount, 0, MAX_AMOUNT));
        int256 value =
            PositionCalculator.calculateValue(PRICE_ONE, PositionCalculator.PositionParams(stableAmount, 0, 0));

        assertEq(value, stableAmount);
    }

    function testCalculateValuePriceOne01(uint256 _sqrtAmount) public {
        int256 sqrtAmount = int256(bound(_sqrtAmount, 0, MAX_AMOUNT));

        int256 value = PositionCalculator.calculateValue(PRICE_ONE, PositionCalculator.PositionParams(0, sqrtAmount, 0));

        assertEq(value, 2 * sqrtAmount);
    }

    function testCalculateValuePriceOne001(uint256 _underlyingAmount) public {
        int256 underlyingAmount = int256(bound(_underlyingAmount, 0, MAX_AMOUNT));

        int256 value =
            PositionCalculator.calculateValue(PRICE_ONE, PositionCalculator.PositionParams(0, 0, underlyingAmount));

        assertEq(value, underlyingAmount);
    }

    function testCalculateValuePrice1500() public {
        int256 value =
            PositionCalculator.calculateValue(3143592407309896027392527, PositionCalculator.PositionParams(0, 0, 1e18));

        assertEq(value, 1574321022);
    }

    function testCalculateValuePrice1500Sqrt() public {
        int256 value =
            PositionCalculator.calculateValue(3143592407309896027392527, PositionCalculator.PositionParams(0, 1e12, 0));

        assertEq(value, 79355428);
    }

    function testCalculateValueFuzz(uint256 _underlyingAmount) public {
        uint256 underlyingAmount = bound(_underlyingAmount, 0, 1e32);

        int256 value = PositionCalculator.calculateValue(
            PRICE_ONE, PositionCalculator.PositionParams(0, -int256(underlyingAmount), int256(underlyingAmount))
        );

        assertLe(value, 0);
    }

    function testCalculateMinValue() public {
        int256 value =
            PositionCalculator.calculateMinValue(PRICE_ONE, PositionCalculator.PositionParams(0, 0, 0), RISK_RATIO);

        assertEq(value, 0);
    }

    function testCalculateMinValueGammaShort() public {
        int256 value = PositionCalculator.calculateMinValue(
            PRICE_ONE, PositionCalculator.PositionParams(0, 7 * 1e6, -3 * 1e6), RISK_RATIO
        );

        assertEq(value, 10280193);
    }

    function testCalculateValueGammaShort() public {
        int256 value = PositionCalculator.calculateValue(
            PRICE_ONE * 1e8 / RISK_RATIO, PositionCalculator.PositionParams(0, 7 * 1e6, -3 * 1e6)
        );

        assertEq(value, 10280193);
    }

    function testCalculateMinValueGammaLong(uint256 _sqrtPrice) public {
        uint256 sqrtPrice = bound(_sqrtPrice, PRICE_ONE * 1e8 / 105000000, PRICE_ONE * 105000000 / 1e8);

        int256 value = PositionCalculator.calculateMinValue(
            sqrtPrice, PositionCalculator.PositionParams(0, -10 * 1e6, 10 * 1e6), RISK_RATIO
        );

        assertEq(value, -10000000);
    }

    function testCalculateMinValueGammaLong2() public {
        uint256 sqrtPrice = PRICE_ONE;

        int256 value = PositionCalculator.calculateMinValue(
            sqrtPrice, PositionCalculator.PositionParams(0, -10 * 1e6, 1 * 1e6), RISK_RATIO
        );

        assertEq(value, -20708903);
    }

    function testCalculateMinValueGammaLongFuzz(uint256 _underlyingAmount) public {
        uint256 underlyingAmount = bound(_underlyingAmount, 0, 1e32);

        int256 value = PositionCalculator.calculateMinValue(
            PRICE_ONE,
            PositionCalculator.PositionParams(0, -int256(underlyingAmount), int256(underlyingAmount)),
            RISK_RATIO
        );

        assertLe(value, 0);
    }
}
