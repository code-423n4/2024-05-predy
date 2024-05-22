// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../../src/lens/PredyPoolQuoter.sol";
import "../../src/lens/PerpMarketQuoter.sol";
import {OrderInfo} from "../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../src/libraries/Constants.sol";
import {PerpOrderV3} from "../../src/markets/perp/PerpOrderV3.sol";
import {PerpMarketLib} from "../../src/markets/perp/PerpMarketLib.sol";

contract TestPerpMarketQuoter is TestLens {
    PerpMarketQuoter _quoter;

    address from;

    function setUp() public override {
        TestLens.setUp();

        IPermit2 permit2 = IPermit2(deployCode("../test-artifacts/Permit2.sol:Permit2"));

        PerpMarket perpMarket = new PerpMarket();

        perpMarket.initialize(predyPool, address(permit2), address(this), address(_predyPoolQuoter));

        perpMarket.updateWhitelistSettlement(address(uniswapSettlement), true);

        _quoter = new PerpMarketQuoter(perpMarket);

        from = vm.addr(1);

        predyPool.createVault(1);

        currency0.approve(address(perpMarket), type(uint256).max);
        currency1.approve(address(perpMarket), type(uint256).max);
    }

    function testQuoteExecuteOrderWithLong() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(0), from, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Buy",
            1000,
            2 * 1e6,
            0,
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        // with settlement contract
        {
            IPredyPool.TradeResult memory tradeResult =
                _quoter.quoteExecuteOrderV3(order, _getUniSettlementDataV3(Constants.Q96 * 12 / 10), address(this));

            assertEq(tradeResult.payoff.perpEntryUpdate, -1002);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with fee
        {
            IPredyPool.TradeResult memory tradeResult = _quoter.quoteExecuteOrderV3(
                order, _getUniSettlementDataV3(Constants.Q96 * 12 / 10, 0, Constants.Q96 / 100), address(this)
            );

            assertEq(tradeResult.payoff.perpEntryUpdate, -1011);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with price
        {
            IPredyPool.TradeResult memory tradeResult = _quoter.quoteExecuteOrderV3(
                order, _getUniSettlementDataV3(Constants.Q96 * 12 / 10, Constants.Q96, 0), address(this)
            );

            assertEq(tradeResult.payoff.perpEntryUpdate, -1000);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with price and fee
        {
            IPredyPool.TradeResult memory tradeResult = _quoter.quoteExecuteOrderV3(
                order,
                _getUniSettlementDataV3(Constants.Q96 * 12 / 10, Constants.Q96, Constants.Q96 / 100),
                address(this)
            );

            assertEq(tradeResult.payoff.perpEntryUpdate, -1009);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with direct
        {
            IPredyPool.TradeResult memory tradeResult =
                _quoter.quoteExecuteOrderV3(order, _getSettlementDataV3(Constants.Q96), address(this));

            assertEq(tradeResult.payoff.perpEntryUpdate, -1000);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }
    }

    function testQuoteExecuteOrderWithShort() public {
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(0), from, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Sell",
            1000,
            2 * 1e6,
            0,
            0,
            2,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(0, 0, 0, 0))
        );

        // with settlement contract
        {
            IPredyPool.TradeResult memory tradeResult =
                _quoter.quoteExecuteOrderV3(order, _getUniSettlementDataV3(0), address(this));

            assertEq(tradeResult.payoff.perpEntryUpdate, 998);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with price
        {
            IPredyPool.TradeResult memory tradeResult =
                _quoter.quoteExecuteOrderV3(order, _getUniSettlementDataV3(0, Constants.Q96, 0), address(this));

            assertEq(tradeResult.payoff.perpEntryUpdate, 1000);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }

        // with direct
        {
            IPredyPool.TradeResult memory tradeResult =
                _quoter.quoteExecuteOrderV3(order, _getSettlementDataV3(Constants.Q96), address(this));

            assertEq(tradeResult.payoff.perpEntryUpdate, 1000);
            assertEq(tradeResult.payoff.sqrtEntryUpdate, 0);
            assertEq(tradeResult.payoff.perpPayoff, 0);
            assertEq(tradeResult.payoff.sqrtPayoff, 0);
        }
    }
}
