// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../../src/lens/PredyPoolQuoter.sol";
import "../../src/lens/GammaTradeMarketQuoter.sol";
import "../../src/markets/gamma/GammaTradeMarket.sol";
import {OrderInfo} from "../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../src/libraries/Constants.sol";

contract TestGammaTradeMarketQuoter is TestLens {
    GammaTradeMarketQuoter _quoter;

    address from;

    function setUp() public override {
        TestLens.setUp();

        IPermit2 permit2 = IPermit2(deployCode("../test-artifacts/Permit2.sol:Permit2"));

        GammaTradeMarket gammaTradeMarket = new GammaTradeMarket();
        gammaTradeMarket.initialize(predyPool, address(permit2), address(this), address(_predyPoolQuoter));
        gammaTradeMarket.updateWhitelistSettlement(address(uniswapSettlement), true);

        _quoter = new GammaTradeMarketQuoter(gammaTradeMarket);

        from = vm.addr(1);

        predyPool.createVault(1);
    }

    function testQuoteExecuteOrder() public {
        GammaOrder memory order = GammaOrder(
            OrderInfo(address(0), from, 0, block.timestamp + 100),
            1,
            0,
            address(currency1),
            -1000,
            1000,
            2 * 1e6,
            0,
            0,
            2,
            GammaModifyInfo(
                false,
                // auto close
                0,
                0,
                0,
                0,
                // auto hedge
                0,
                0,
                // slippage tolerance
                0,
                0,
                0,
                0
            )
        );

        IFillerMarket.SettlementParamsV3 memory settlementData = _getUniSettlementDataV3(0);

        IPredyPool.TradeResult memory tradeResult = _quoter.quoteTrade(order, settlementData);

        assertEq(tradeResult.payoff.perpEntryUpdate, 1000);
        assertEq(tradeResult.payoff.sqrtEntryUpdate, -2000);
        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);
    }
}
