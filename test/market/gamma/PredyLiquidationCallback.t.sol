// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract TestPredyLiquidationCallback is TestGammaMarket {
    function setUp() public override {
        TestGammaMarket.setUp();
    }

    // liquidate a filler market position
}
