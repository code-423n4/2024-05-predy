// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Bps} from "../../../src/libraries/math/Bps.sol";
import {PerpMarketV1} from "../../../src/markets/perp/PerpMarketV1.sol";
import "../../../src/markets/perp/PerpMarket.sol";
import {PerpOrderV3} from "../../../src/markets/perp/PerpOrderV3.sol";
import {PerpMarketLib} from "../../../src/markets/perp/PerpMarketLib.sol";
import {MockPriceFeed} from "../../mocks/MockPriceFeed.sol";
import {SignatureVerification} from "@uniswap/permit2/src/libraries/SignatureVerification.sol";

contract TestPerpExecuteOrderV3 is TestPerpMarket {
    bytes normalSwapRoute;
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;

    MockPriceFeed private _priceFeed;

    uint256 MIN_QUOTE_PRICE = Constants.Q96 * 11 / 10;
    uint256 MAX_QUOTE_PRICE = Constants.Q96 * 10 / 11;

    function setUp() public override {
        TestPerpMarket.setUp();

        _priceFeed = new MockPriceFeed();

        _priceFeed.setSqrtPrice(2 ** 96);

        registerPair(address(currency1), address(_priceFeed));
        perpMarket.updateQuoteTokenMap(1);

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

        normalSwapRoute = abi.encodePacked(address(currency0), uint24(500), address(currency1));

        fromPrivateKey1 = 0x12341234;
        from1 = vm.addr(fromPrivateKey1);
        fromPrivateKey2 = 0x1235678;
        from2 = vm.addr(fromPrivateKey2);

        currency1.mint(from1, 2 ** 250);
        currency1.mint(from2, 2 ** 250);

        vm.prank(from1);
        currency1.approve(address(permit2), type(uint256).max);

        vm.prank(from2);
        currency1.approve(address(permit2), type(uint256).max);
    }

    function testAmountIsZeroSignature() public {
        assertEq(
            PerpMarketV1.AmountIsZero.selector,
            bytes32(0x43ad20fc00000000000000000000000000000000000000000000000000000000)
        );
    }

    // executeOrderV3 succeeds for open(pnl, interest, premium, borrow fee)
    function testExecuteOrderV3SucceedsForOpen() public {
        uint256 balance0 = currency1.balanceOf(from1);

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                2 * 1e6,
                2 * 1e6 * 101 / 100,
                0,
                0,
                1,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

            vm.startPrank(from1);
            vm.expectRevert(IFillerMarket.CallerIsNotFiller.selector);
            perpMarket.executeOrderV3(signedOrder, settlementData);
            vm.stopPrank();

            IPredyPool.TradeResult memory tradeResult = perpMarket.executeOrderV3(signedOrder, settlementData);

            assertEq(tradeResult.payoff.perpEntryUpdate, 1998999);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        uint256 balance1 = currency1.balanceOf(from1);

        // Close position by trader
        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                2 * 1e6,
                0,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(2 * Constants.Q96, 2 * Constants.Q96, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            vm.startPrank(from1);
            IPredyPool.TradeResult memory tradeResult2 =
                perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(MIN_QUOTE_PRICE));
            vm.stopPrank();

            assertEq(tradeResult2.payoff.perpEntryUpdate, -1998999);
            assertEq(tradeResult2.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult2.payoff.perpPayoff, -2004);
            assertEq(tradeResult2.payoff.sqrtPayoff, 0);
        }

        uint256 balance2 = currency1.balanceOf(from1);

        assertEq(balance0 - balance1, 2001001);
        assertEq(balance2 - balance1, 1998997);
    }

    // reduce and increase position
    function testExecuteOrderV3SucceedsWithReducingAndIncreasing() public {
        uint256 balance0 = currency1.balanceOf(from1);

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                1000 * 1e4,
                2 * 1e8,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(0));
        }

        uint256 balance1 = currency1.balanceOf(from1);

        uint256 snapshot = vm.snapshot();

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                500 * 1e4,
                0,
                calculateLimitPrice(1200, 1000),
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(MIN_QUOTE_PRICE));

            uint256 balance2 = currency1.balanceOf(from1);

            assertEq(balance0 - balance1, 5005001);
            assertEq(balance2 - balance1, 2497498);
        }

        vm.revertTo(snapshot);

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                500 * 1e4,
                1e8,
                calculateLimitPrice(800, 1000),
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(400 * 1e4));
        }

        uint256 balance3 = currency1.balanceOf(from1);

        assertEq(balance1 - balance3, 2502501);
    }

    function testExecuteOrderV3WithReduceOnly() public {
        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                1000 * 1e4,
                2 * 1e8,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(0));
        }

        uint256 snapshot = vm.snapshot();

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                500 * 1e4,
                0,
                calculateLimitPrice(1200, 1000),
                0,
                2,
                true,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(MIN_QUOTE_PRICE));
        }

        vm.revertTo(snapshot);

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                500 * 1e4,
                1e8,
                calculateLimitPrice(800, 1000),
                0,
                2,
                true,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(MIN_QUOTE_PRICE);

            vm.expectRevert(PerpMarketV1.AmountIsZero.selector);
            perpMarket.executeOrderV3(signedOrder, settlementData);
        }
    }

    function testExecuteOrderV3WithClosePosition() public {
        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                1000 * 1e4,
                2 * 1e8,
                0,
                0,
                2,
                false,
                true,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

            vm.expectRevert(PerpMarketV1.AmountIsZero.selector);
            perpMarket.executeOrderV3(signedOrder, settlementData);
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                1000 * 1e4,
                2 * 1e8,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(0));
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                0,
                0,
                calculateLimitPrice(1200, 1000),
                0,
                2,
                false,
                true,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(MIN_QUOTE_PRICE));
        }
    }

    // executeOrderV3 failed if mount is 0
    function testExecuteOrderFailedBecauseAmoutIsZero() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Buy",
            0,
            1e7,
            0,
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

        vm.expectRevert(PerpMarketV1.AmountIsZero.selector);
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    function testAvoidFreeze() public {
        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                1e7,
                1e7,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(0));
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                1e7,
                1e7,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(2 * Constants.Q96, 2 * Constants.Q96, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(MIN_QUOTE_PRICE);

            perpMarket.executeOrderV3(signedOrder, settlementData);
        }

        assertEq(currency1.balanceOf(address(perpMarket)), 0);
    }

    // executeOrderV3 fails if deadline passed
    function testExecuteOrderFails_IfDeadlinePassed() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, 1),
            1,
            address(currency1),
            "Buy",
            1000,
            2 * 1e6,
            calculateLimitPrice(1200, 1000),
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(MIN_QUOTE_PRICE);

        vm.expectRevert();
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    // executeOrderV3 fails if signature is invalid
    function testExecuteOrderFails_IfSignerIsNotOwner() public {
        IFillerMarket.SettlementParamsV3 memory settlementDataForLong = _getUniSettlementDataV3(MIN_QUOTE_PRICE);
        IFillerMarket.SettlementParamsV3 memory settlementDataForShort = _getUniSettlementDataV3(MAX_QUOTE_PRICE);

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp),
                1,
                address(currency1),
                "Buy",
                1e7,
                1e7,
                calculateLimitPrice(1200, 1000),
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, settlementDataForLong);
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp),
                1,
                address(currency1),
                "Sell",
                1e7,
                0,
                calculateLimitPrice(800, 1000),
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey2);

            vm.expectRevert(SignatureVerification.InvalidSigner.selector);
            perpMarket.executeOrderV3(signedOrder, settlementDataForShort);
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from2, 0, block.timestamp),
                1,
                address(currency1),
                "Buy",
                1e7,
                2 * 1e7,
                calculateLimitPrice(1200, 1000),
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            vm.expectRevert(SignatureVerification.InvalidSigner.selector);
            perpMarket.executeOrderV3(signedOrder, settlementDataForLong);
        }
    }

    // executeOrderV3 fails if price is greater than limit
    function testExecuteOrderFails_IfPriceIsGreaterThanLimit() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Buy",
            1e7,
            1e7,
            calculateLimitPrice(999, 1000),
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(MIN_QUOTE_PRICE);

        vm.expectRevert(PerpMarketLib.LimitPriceDoesNotMatch.selector);
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    // executeOrderV3 fails if price is less than limit
    function testExecuteOrderFails_IfPriceIsLessThanLimit() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Sell",
            1e7,
            1e7,
            calculateLimitPrice(1001, 1000),
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

        vm.expectRevert(PerpMarketLib.LimitPriceDoesNotMatch.selector);
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    // executeOrderV3 fails if price is less than stop price
    function testExecuteOrderFailsIfPriceIsLessThanStopPrice() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Buy",
            1e7,
            1e7,
            0,
            calculateLimitPrice(1001, 1000),
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(MIN_QUOTE_PRICE);

        vm.expectRevert(PerpMarketLib.StopPriceDoesNotMatch.selector);
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    // executeOrderV3 fails if price is greater than stop price
    function testExecuteOrderFailsIfPriceIsGreaterThanStopPrice() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Sell",
            1e7,
            1e7,
            0,
            calculateLimitPrice(999, 1000),
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

        vm.expectRevert(PerpMarketLib.StopPriceDoesNotMatch.selector);
        perpMarket.executeOrderV3(signedOrder, settlementData);
    }

    // check large amount
    function testExecuteOrderV3Fuzz(uint256 sqrtPrice) public {
        sqrtPrice = bound(sqrtPrice, 2 ** 90, 2 ** 156);

        predyPool.supply(1, true, 2 ** 180);
        predyPool.supply(1, false, 2 ** 180);

        _priceFeed.setSqrtPrice(sqrtPrice);
        uint256 price = Math.calSqrtPriceToPrice(sqrtPrice);

        uint256 amount = 1e10;
        uint256 margin = price * amount / 2 ** 96;

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
                1,
                address(currency1),
                "Sell",
                amount,
                margin * 101 / 100,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getDebugSettlementDataV3(price, 0);

            perpMarket.executeOrderV3(signedOrder, settlementData);
        }

        {
            PerpOrderV3 memory order = PerpOrderV3(
                OrderInfo(address(perpMarket), from1, 1, block.timestamp + 100),
                1,
                address(currency1),
                "Buy",
                amount,
                0,
                0,
                0,
                2,
                false,
                false,
                abi.encode(PerpMarketLib.AuctionParams(type(uint256).max, type(uint256).max, 0, 0))
            );

            IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

            perpMarket.executeOrderV3(signedOrder, _getDebugSettlementDataV3(price, price * 101 / 100));
        }
    }

    function testExecuteOrderV3L2() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Sell",
            2 * 1e6,
            2 * 1e6 * 101 / 100,
            0,
            0,
            1,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        PerpOrderV3L2 memory orderL2 = PerpOrderV3L2(
            order.info.trader,
            order.info.nonce,
            order.quantity,
            order.marginAmount,
            order.limitPrice,
            order.stopPrice,
            encodePerpOrderV3Params(
                uint64(order.info.deadline),
                uint64(order.pairId),
                uint8(order.leverage),
                order.reduceOnly,
                order.closePosition,
                // Sell
                false
            ),
            order.auctionData
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

        perpMarket.executeOrderV3L2(orderL2, signedOrder.sig, settlementData, 0);
    }
}
