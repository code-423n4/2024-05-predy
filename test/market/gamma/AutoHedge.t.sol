// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../../src/libraries/Constants.sol";
import {MockPriceFeed} from "../../mocks/MockPriceFeed.sol";
import {Bps} from "../../../src/libraries/math/Bps.sol";

contract TestGammaAutoHedge is TestGammaMarket {
    bytes normalSwapRoute;
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;
    MockPriceFeed mockPriceFeed;

    function setUp() public override {
        TestGammaMarket.setUp();

        mockPriceFeed = new MockPriceFeed();
        mockPriceFeed.setSqrtPrice(Constants.Q96);

        registerPair(address(currency1), address(mockPriceFeed));

        gammaTradeMarket.updateQuoteTokenMap(1);

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

        normalSwapRoute = abi.encodePacked(address(currency0), uint24(500), address(currency1));

        fromPrivateKey1 = 0x12341234;
        from1 = vm.addr(fromPrivateKey1);
        fromPrivateKey2 = 0x1235678;
        from2 = vm.addr(fromPrivateKey2);

        currency1.mint(from1, type(uint128).max);
        currency1.mint(from2, type(uint128).max);

        vm.prank(from1);
        currency1.approve(address(permit2), type(uint256).max);

        vm.prank(from2);
        currency1.approve(address(permit2), type(uint256).max);

        GammaOrder memory order = GammaOrder(
            OrderInfo(address(gammaTradeMarket), from1, 0, block.timestamp + 100),
            1,
            0,
            address(currency1),
            -9 * 1e6,
            10 * 1e6,
            2 * 1e6,
            Constants.Q96,
            1e6 + 5000, // 0.5%
            2,
            GammaModifyInfo(
                true,
                // auto close
                uint64(block.timestamp + 2 hours),
                // maximumDevietion is -0.01%
                -100,
                0,
                0,
                // auto hedge
                2 hours,
                1e6 + 12000, // +-1.2% range in sqrt
                // 30bps - 60bps
                Bps.ONE + 3000,
                Bps.ONE + 6000,
                10 minutes,
                10000
            )
        );

        gammaTradeMarket.executeTrade(order, _sign(order, fromPrivateKey1), _getSettlementDataV3(Constants.Q96));
    }

    function testCannotExecuteDeltaHedgeByTime() public {
        mockPriceFeed.setSqrtPrice(Constants.Q96);

        vm.warp(block.timestamp + 1 hours);

        IFillerMarket.SettlementParamsV3 memory settlementParams = _getSettlementDataV3(Constants.Q96);

        vm.expectRevert(GammaTradeMarket.HedgeTriggerNotMatched.selector);
        gammaTradeMarket.autoHedge(1, settlementParams);
    }

    function testCannotAutoHedgeAfterClosed() public {
        mockPriceFeed.setSqrtPrice(Constants.Q96);

        vm.warp(block.timestamp + 3 hours);

        IFillerMarket.SettlementParamsV3 memory settlementParams = _getSettlementDataV3(Constants.Q96);

        gammaTradeMarket.autoClose(1, settlementParams);

        vm.expectRevert(GammaTradeMarket.DeltaIsZero.selector);
        gammaTradeMarket.autoHedge(1, settlementParams);
    }

    function testSucceedsExecuteDeltaHedgeByTime() public {
        mockPriceFeed.setSqrtPrice(Constants.Q96);

        vm.warp(block.timestamp + 3 hours);

        gammaTradeMarket.autoHedge(1, _getSettlementDataV3(Constants.Q96));
    }

    function testExecuteDeltaHedgeByPrice() public {
        mockPriceFeed.setSqrtPrice(Constants.Q96 * 1014 / 1000);

        _movePrice(true, 1e16);

        vm.warp(block.timestamp + 1 hours);

        IFillerMarket.SettlementParamsV3 memory settlementParams = _getSettlementDataV3(Constants.Q96 * 1028 / 1000);

        gammaTradeMarket.autoHedge(1, settlementParams);
    }
}
