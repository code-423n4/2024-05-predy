// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {GammaTradeMarketLib} from "../../../src/markets/gamma/GammaTradeMarketLib.sol";

contract TestGammaTradeMarketLib is Test {
    function testCalSlippageToleranceByTime() public {
        GammaTradeMarketLib.AuctionParams memory auctionParams =
            GammaTradeMarketLib.AuctionParams(1000, 11000, 10 minutes, 0);

        assertEq(GammaTradeMarketLib.calculateSlippageTolerance(10 minutes, 0, auctionParams), 1000);

        assertEq(GammaTradeMarketLib.calculateSlippageTolerance(10 minutes, 10 minutes, auctionParams), 1000);

        assertEq(GammaTradeMarketLib.calculateSlippageTolerance(10 minutes, 15 minutes, auctionParams), 6000);

        assertEq(GammaTradeMarketLib.calculateSlippageTolerance(10 minutes, 20 minutes, auctionParams), 11000);

        assertEq(GammaTradeMarketLib.calculateSlippageTolerance(10 minutes, 1 hours, auctionParams), 11000);
    }

    function testCalSlippageToleranceByPrice() public {
        GammaTradeMarketLib.AuctionParams memory auctionParams =
            GammaTradeMarketLib.AuctionParams(1000, 11000, 0, 10000);

        assertEq(GammaTradeMarketLib.calculateSlippageToleranceByPrice(10000, 9000, auctionParams), 1000);

        assertEq(GammaTradeMarketLib.calculateSlippageToleranceByPrice(10000, 10000, auctionParams), 1000);

        assertEq(GammaTradeMarketLib.calculateSlippageToleranceByPrice(10000, 10050, auctionParams), 6000);

        assertEq(GammaTradeMarketLib.calculateSlippageToleranceByPrice(10000, 10100, auctionParams), 11000);

        assertEq(GammaTradeMarketLib.calculateSlippageToleranceByPrice(10000, 10500, auctionParams), 11000);
    }
}
