// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract TestPredyLiquidationCallback is TestPerpMarket {
    function setUp() public override {
        TestPerpMarket.setUp();
    }

    // liquidate a filler market position
}
