// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/libraries/Perp.sol";

contract TestPerpCalculateEntry is Test {
    function checkEntryCalculation(
        int256 _positionAmount,
        int256 _entryValue,
        int256 _tradeAmount,
        int256 _valueUpdate,
        int256 _expectedEntryUpdate,
        int256 _expectedPayoff
    ) internal {
        (int256 entryUpdate, int256 payoff) =
            Perp.calculateEntry(_positionAmount, _entryValue, _tradeAmount, _valueUpdate);

        assertEq(entryUpdate, _expectedEntryUpdate);
        assertEq(payoff, _expectedPayoff);
    }

    // Open positions
    function testZero() public {
        checkEntryCalculation(0, 0, 0, 0, 0, 0);
    }

    function testOpenLongInExForShort() public {
        checkEntryCalculation(0, 0, 100, -100, -100, 0);
    }

    function testOpenLongInExForLong() public {
        checkEntryCalculation(0, 0, 100, 100, 100, 0);
    }

    function testOpenShortInExForLong() public {
        checkEntryCalculation(0, 0, -100, 100, 100, 0);
    }

    // Close positions
    function testCloseLongInExForLong() public {
        checkEntryCalculation(100, -100, -100, 100, 100, 0);
    }

    function testCloseLongInExForShort() public {
        checkEntryCalculation(100, 100, -100, -100, -100, 0);
    }

    function testCloseLongPartially() public {
        checkEntryCalculation(100, -100, -10, 10, 10, 0);
    }

    function testCloseLongWithProfit() public {
        checkEntryCalculation(100, -100, -50, 70, 50, 20);
    }

    function testCloseLongAndOpenShort() public {
        checkEntryCalculation(100, -100, -150, 150, 150, 0);
    }
}
