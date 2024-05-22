// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Setup.t.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract TestPerpReallocate is TestPerp {
    function setUp() public override {
        TestPerp.setUp();

        ScaledAsset.addAsset(pairStatus.basePool.tokenStatus, 1000000);
        ScaledAsset.addAsset(pairStatus.quotePool.tokenStatus, 1000000);
    }

    function testReallocate() public {
        Perp.computeRequiredAmounts(pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, userStatus, 1000000);
        Perp.updatePosition(
            pairStatus, userStatus, Perp.UpdatePerpParams(-100, 100), Perp.UpdateSqrtPerpParams(1000000, -100)
        );

        uniswapPool.swap(address(this), false, 10000, TickMath.MAX_SQRT_RATIO - 1, "");

        Perp.reallocate(pairStatus, pairStatus.sqrtAssetStatus);

        assertEq(pairStatus.sqrtAssetStatus.tickLower, -900);
        assertEq(pairStatus.sqrtAssetStatus.tickUpper, 1090);
    }
}
