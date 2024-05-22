// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {SignatureVerification} from "@uniswap/permit2/src/libraries/SignatureVerification.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../../src/libraries/Constants.sol";
import {SlippageLib} from "../../../src/libraries/SlippageLib.sol";

contract TestGammaExecuteOrder is TestGammaMarket {
    bytes normalSwapRoute;
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;

    function setUp() public override {
        TestGammaMarket.setUp();

        registerPair(address(currency1), address(0));
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
    }

    // executeTrade succeeds for open(pnl, interest, premium, borrow fee)
    function testExecuteOrderSucceedsForOpen() public {
        GammaOrder memory order =
            _createOrder(from1, 0, block.timestamp + 100, 1, 0, -1000, 1000, 2 * 1e6, Constants.Q96);

        IPredyPool.TradeResult memory tradeResult =
            gammaTradeMarket.executeTrade(order, _sign(order, fromPrivateKey1), _getSettlementDataV3(Constants.Q96));

        assertEq(tradeResult.payoff.perpEntryUpdate, 1000);
        assertEq(tradeResult.payoff.sqrtEntryUpdate, -2000);
        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);
    }

    // executeTrade fails if deadline passed
    function testExecuteOrderFails_IfDeadlinePassed() public {
        GammaOrder memory order = _createOrder(from1, 0, 1, 1, 0, 1000, 0, 2 * 1e6, Constants.Q96);

        bytes memory signature = _sign(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getSettlementDataV3(Constants.Q96);

        vm.expectRevert();
        gammaTradeMarket.executeTrade(order, signature, settlementData);
    }

    // executeTrade fails if signature is invalid
    function testExecuteOrderFails_IfSignerIsNotOwner() public {
        IFillerMarket.SettlementParamsV3 memory settlementData = _getSettlementDataV3(Constants.Q96);

        {
            GammaOrder memory order = _createOrder(from1, 0, block.timestamp, 1, 0, -1000, 1000, 2 * 1e6, Constants.Q96);

            gammaTradeMarket.executeTrade(order, _sign(order, fromPrivateKey1), settlementData);
        }

        {
            GammaOrder memory order = _createOrder(from1, 1, block.timestamp, 1, 0, 1000, -1000, 0, Constants.Q96);

            bytes memory signature = _sign(order, fromPrivateKey2);

            vm.expectRevert(SignatureVerification.InvalidSigner.selector);
            gammaTradeMarket.executeTrade(order, signature, settlementData);
        }
    }

    // executeTrade fails if price is greater than limit
    function testOpenFails_IfValueISLessThanLimit() public {
        GammaOrder memory order =
            _createOrder(from1, 0, block.timestamp + 100, 1, 0, -1000, 1000, 2 * 1e6, Constants.Q96 * 10 / 9);

        bytes memory signature = _sign(order, fromPrivateKey1);

        IFillerMarket.SettlementParamsV3 memory settlementData = _getSettlementDataV3(Constants.Q96);

        vm.expectRevert(SlippageLib.SlippageTooLarge.selector);
        gammaTradeMarket.executeTrade(order, signature, settlementData);
    }

    // executeTrade fails if price is less than limit
    function testCloseFails_IfValueISLessThanLimit() public {
        {
            GammaOrder memory order = _createOrder(from1, 0, block.timestamp, 1, 0, -1000, 1000, 2 * 1e6, Constants.Q96);

            bytes memory signature = _sign(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getSettlementDataV3(Constants.Q96);

            gammaTradeMarket.executeTrade(order, signature, settlementData);
        }

        {
            GammaOrder memory order =
                _createOrder(from1, 1, block.timestamp + 100, 1, 1, 1000, -1000, 0, Constants.Q96 * 9 / 10);

            bytes memory signature = _sign(order, fromPrivateKey1);

            IFillerMarket.SettlementParamsV3 memory settlementData = _getSettlementDataV3(Constants.Q96);

            vm.expectRevert(SlippageLib.SlippageTooLarge.selector);
            gammaTradeMarket.executeTrade(order, signature, settlementData);
        }
    }
}
