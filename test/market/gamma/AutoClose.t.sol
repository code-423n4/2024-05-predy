// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../../src/libraries/Constants.sol";
import {MockPriceFeed} from "../../mocks/MockPriceFeed.sol";

contract TestGammaAutoClose is TestGammaMarket {
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;
    MockPriceFeed mockPriceFeed;

    function setUp() public override {
        TestGammaMarket.setUp();

        mockPriceFeed = new MockPriceFeed();

        registerPair(address(currency1), address(mockPriceFeed));

        gammaTradeMarket.updateQuoteTokenMap(1);

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

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
            -900,
            1000,
            2 * 1e6,
            Constants.Q96,
            1e6 + 5000, // 0.5%
            2,
            GammaModifyInfo(
                true,
                // auto close
                uint64(block.timestamp + 2 hours),
                0,
                0,
                0,
                // auto hedge
                0,
                0,
                // 30bps - 60bps
                1e6 + 3000,
                1e6 + 6000,
                10 minutes,
                10000
            )
        );

        gammaTradeMarket.executeTrade(order, _sign(order, fromPrivateKey1), _getSettlementDataV3(Constants.Q96));
    }

    function testCannotAutoClose() public {
        mockPriceFeed.setSqrtPrice(2 ** 96);

        vm.warp(block.timestamp + 1 hours);

        IFillerMarket.SettlementParamsV3 memory settlementParams = _getSettlementDataV3(Constants.Q96);

        vm.expectRevert(GammaTradeMarket.AutoCloseTriggerNotMatched.selector);
        gammaTradeMarket.autoClose(1, settlementParams);
    }

    function testSucceedsAutoClose() public {
        mockPriceFeed.setSqrtPrice(Constants.Q96);

        vm.warp(block.timestamp + 3 hours);

        IFillerMarket.SettlementParamsV3 memory settlementParams = _getSettlementDataV3(Constants.Q96);

        gammaTradeMarket.autoClose(1, settlementParams);

        vm.expectRevert(GammaTradeMarket.AlreadyClosed.selector);
        gammaTradeMarket.autoClose(1, settlementParams);
    }
}
