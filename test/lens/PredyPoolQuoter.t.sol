// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract TestPredyPoolQuoter is TestLens {
    function setUp() public override {
        TestLens.setUp();

        predyPool.createVault(1);
    }

    function testQuotePairStatus() public {
        DataType.PairStatus memory pairStatus = _predyPoolQuoter.quotePairStatus(1);

        assertEq(pairStatus.id, 1);
    }

    function testQuoteBaseAmountDeltaFails() public {
        vm.expectRevert(IPredyPool.InvalidPairId.selector);
        _predyPoolQuoter.quoteBaseAmountDelta(IPredyPool.TradeParams(0, 1, 0, 0, bytes("")));
    }

    function testQuoteReallocation() public {
        int256 baseAmount = _predyPoolQuoter.quoteReallocation(1);

        assertEq(baseAmount, 0);
    }

    function testQuoteVaultStatus() public {
        IPredyPool.VaultStatus memory vaultStatus = _predyPoolQuoter.quoteVaultStatus(1);

        assertEq(vaultStatus.id, 1);
    }

    function testQuoteTradeResult() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -1000, 900, abi.encode(_getTradeAfterParams(1e6)));

        IFillerMarket.SettlementParams memory settlementData = _getUniSettlementData(0);

        IPredyPool.TradeResult memory tradeResult = _predyPoolQuoter.quoteTrade(tradeParams, settlementData);

        assertEq(tradeResult.payoff.perpEntryUpdate, 980);
        assertEq(tradeResult.payoff.sqrtEntryUpdate, -1782);
        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);
    }
}
