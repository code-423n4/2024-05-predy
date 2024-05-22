// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./Setup.t.sol";

contract TestPerpComputeRequiredAmounts is TestPerp {
    function setUp() public override {
        TestPerp.setUp();
    }

    function testEmpty() public {
        (int256 requiredAmountUnderlying, int256 requiredAmountStable) =
            Perp.computeRequiredAmounts(pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, userStatus, 0);

        assertEq(requiredAmountUnderlying, 0);
        assertEq(requiredAmountStable, 0);
    }

    // Opens long position
    // u = L / sqrt(x) = 10000 / 1
    // s = L * (sqrt(x) - sqrt(-100)) = 10000 * (1 - 0.995)
    function testOpenLong() public {
        (int256 requiredAmountUnderlying, int256 requiredAmountStable) =
            Perp.computeRequiredAmounts(pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, userStatus, 10000);

        assertEq(requiredAmountUnderlying, -10000);
        assertEq(requiredAmountStable, -10000);
    }

    function testOpenShort() public {
        Perp.computeRequiredAmounts(pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, userStatus, 20000);
        pairStatus.sqrtAssetStatus.totalAmount += 20000;

        (int256 requiredAmountUnderlying, int256 requiredAmountStable) =
            Perp.computeRequiredAmounts(pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, userStatus, -10000);

        assertEq(requiredAmountUnderlying, 10000);
        assertEq(requiredAmountStable, 10000);
    }
}
