// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../mocks/TestTradeMarket.sol";
import "../mocks/TestSettlement.sol";

contract TestTrade is TestPool {
    TestTradeMarket tradeMarket;
    TestTradeMarket tradeMarket2;
    TestSettlementCurrencyNotSettled testSettlementCurrencyNotSettled;
    TestSettlementReentrant testSettlementReentrant;

    uint256 whitelistPairId;

    function setUp() public override {
        TestPool.setUp();

        registerPair(address(currency1), address(0), false);
        whitelistPairId = registerPair(address(currency1), address(0), true);

        predyPool.supply(1, true, 1e8);
        predyPool.supply(1, false, 1e8);
        predyPool.supply(whitelistPairId, true, 1e8);
        predyPool.supply(whitelistPairId, false, 1e8);

        tradeMarket = new TestTradeMarket(predyPool);
        tradeMarket2 = new TestTradeMarket(predyPool);
        testSettlementCurrencyNotSettled = new TestSettlementCurrencyNotSettled(predyPool);
        testSettlementReentrant = new TestSettlementReentrant(predyPool);

        currency1.transfer(address(tradeMarket), 1e10);

        currency0.approve(address(tradeMarket), 1e10);
        currency1.approve(address(tradeMarket), 1e10);

        currency0.transfer(address(testSettlementCurrencyNotSettled), 1e8);
        currency1.transfer(address(testSettlementCurrencyNotSettled), 1e8);

        currency0.transfer(address(testSettlementReentrant), 1e8);
        currency1.transfer(address(testSettlementReentrant), 1e8);
    }

    function testTradeSucceeds() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -900, 1000, abi.encode(_getTradeAfterParams(1e6)));

        IPredyPool.TradeResult memory tradeResult = tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        assertEq(tradeResult.payoff.perpEntryUpdate, 900);
        assertEq(tradeResult.payoff.sqrtEntryUpdate, -2000);
        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);

        DataType.Vault memory vault = predyPool.getVault(1);

        assertEq(vault.margin, 1e6);
    }

    // trade succeeds for close
    function testTradeSucceedsForClose() public {
        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -99 * 1e4, 0, abi.encode(_getTradeAfterParams(1e8))),
            _getSettlementData(Constants.Q96)
        );

        IPredyPool.TradeResult memory tradeResult = tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, 99 * 1e4, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);
    }

    function testTradeSucceedsWithNetZero() public {
        _movePrice(true, 4 * 1e16);

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -960, 1000, abi.encode(_getTradeAfterParams(2 * 1e6)));

        IPredyPool.TradeResult memory tradeResult = tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        assertEq(tradeResult.payoff.perpEntryUpdate, 1041);
        assertEq(tradeResult.payoff.sqrtEntryUpdate, -2083);
        assertEq(tradeResult.payoff.perpPayoff, 0);
        assertEq(tradeResult.payoff.sqrtPayoff, 0);
        assertEq(tradeResult.averagePrice, 85968058283706963578677050285);

        DataType.Vault memory vault = predyPool.getVault(1);

        assertEq(vault.margin, 2 * 1e6);
    }

    // trade succeeds with zero amount
    function testTradeSucceedsWithZeroAmount() public {
        IPredyPool.TradeResult memory tradeResult1 = tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -1e7, 9 * 1e6, abi.encode(_getTradeAfterParams(1e8))),
            _getSettlementData(Constants.Q96)
        );

        vm.warp(block.timestamp + 10 hours);

        IPredyPool.TradeResult memory tradeResult2 = tradeMarket.trade(
            IPredyPool.TradeParams(1, tradeResult1.vaultId, 0, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        assertEq(tradeResult2.payoff.perpEntryUpdate, 0);
        assertEq(tradeResult2.payoff.sqrtEntryUpdate, 0);
        assertEq(tradeResult2.payoff.perpPayoff, 0);
        assertEq(tradeResult2.payoff.sqrtPayoff, 0);
        assertEq(tradeResult2.fee, -29);
        assertEq(tradeResult2.averagePrice, -79228162514264337593543950336);

        DataType.Vault memory vault = predyPool.getVault(1);

        assertEq(vault.margin, 99999971);
    }

    // trade fails if currency not settled
    function testCannotTradeIfCurrencyNotSettled(uint256 a, uint256 b) public {
        int256 baseTokenAmount = int256(bound(a, 0, 1000000)) - 500000;
        int256 quoteTokenAmount = int256(bound(b, 0, 1000000)) - 500000;

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -900, 1000, abi.encode(_getTradeAfterParams(1e8)));
        bytes memory settlementData = abi.encode(
            TestSettlementCurrencyNotSettled.SettlementParams(
                address(currency0), address(currency1), baseTokenAmount, quoteTokenAmount
            )
        );

        if (baseTokenAmount != -100) {
            vm.expectRevert(IPredyPool.BaseTokenNotSettled.selector);
        } else if (quoteTokenAmount <= 0) {
            vm.expectRevert(IPredyPool.QuoteTokenNotSettled.selector);
        }
        testSettlementCurrencyNotSettled.trade(tradeParams, settlementData);
    }

    // trade fails if caller is not vault owner
    function testTradeFails_IfCallerIsNotVaultOwner() public {
        IPredyPool.TradeResult memory tradeResult = tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -99 * 1e4, 0, abi.encode(_getTradeAfterParams(1e8))),
            _getSettlementData(Constants.Q96)
        );

        bytes memory extraData = abi.encode(_getTradeAfterParams(0));

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        vm.expectRevert(IPredyPool.CallerIsNotVaultOwner.selector);
        tradeMarket2.trade(IPredyPool.TradeParams(1, tradeResult.vaultId, 99 * 1e4, 0, extraData), settlementData);
    }

    function testTradeFails_IfCallerIsNotAllowed() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(whitelistPairId, 0, -900, 1000, abi.encode(_getTradeAfterParams(1e6)));

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        vm.expectRevert(IPredyPool.TraderNotAllowed.selector);
        tradeMarket.trade(tradeParams, settlementData);

        predyPool.allowTrader(whitelistPairId, address(tradeMarket), true);

        tradeMarket.trade(tradeParams, settlementData);
    }

    // trade fails if pairId does not exist
    function testTradeFailsIfPairIdDoesNotExist() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(100, 0, -900, 1000, abi.encode(_getTradeAfterParams(1e6)));

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        vm.expectRevert(IPredyPool.InvalidPairId.selector);
        tradeMarket.trade(tradeParams, settlementData);
    }

    // trade fails if the vault is not safe
    function testTradeFailsIfVaultIsNotSafe(uint256 marginAmount) public {
        marginAmount = bound(marginAmount, 0, 1e8);

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, 1e8, 0, abi.encode(_getTradeAfterParams(marginAmount)));

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        if (marginAmount < 16658333) {
            vm.expectRevert(PositionCalculator.NotSafe.selector);
        }
        tradeMarket.trade(tradeParams, settlementData);
    }

    // trade fails if asset can not cover borrow
    function testTradeFailsIfAssetCanNotCoverBorrow(uint256 tradeAmount) public {
        tradeAmount = bound(tradeAmount, 0, 1e10);

        currency1.transfer(address(predyPool), 1e10);

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, int256(tradeAmount), 0, abi.encode(_getTradeAfterParams(1e10)));
        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        if (tradeAmount > 100000000) {
            vm.expectRevert(bytes("S0"));
        }
        tradeMarket.trade(tradeParams, settlementData);
    }

    // trade fails if sqrt liquidity can not cover sqrt borrow
    function testTradeFailsIfSqrtLiquidityCanNotCoverBorrow(uint256 borrowAmount) public {
        borrowAmount = bound(borrowAmount, 0, 20000);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -9000, 10000, abi.encode(_getTradeAfterParams(1e8))),
            _getSettlementData(Constants.Q96)
        );

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, 10000, -int256(borrowAmount), abi.encode(_getTradeAfterParams(1e8)));
        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        if (borrowAmount > 10000) {
            vm.expectRevert(Perp.NoCFMMLiquidityError.selector);
        } else if (borrowAmount > 9800) {
            // 98% of liquidity is available
            vm.expectRevert(Perp.SqrtAssetCanNotCoverBorrow.selector);
        }
        tradeMarket.trade(tradeParams, settlementData);
    }

    // trade fails if current tick is not within safe range
    function testTradeFailsIfCurrentTickIsNotInRange() public {
        {
            IPredyPool.TradeParams memory tradeParams =
                IPredyPool.TradeParams(1, 0, -900, 1000, abi.encode(_getTradeAfterParams(1e6)));

            tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));
        }

        _movePrice(true, 5 * 1e16);

        {
            IPredyPool.TradeParams memory tradeParams =
                IPredyPool.TradeParams(1, 0, 400, -500, abi.encode(_getTradeAfterParams(1e6)));

            IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

            vm.expectRevert(Perp.OutOfRangeError.selector);
            tradeMarket.trade(tradeParams, settlementData);
        }
    }

    // trade fails in callback
    function testCannotTradeReentrant() public {
        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(1, 0, -900, 1000, "");
        bytes memory settlementData = abi.encode(
            TestSettlementReentrant.SettlementParams(
                address(currency1), 100, 70, tradeParams, abi.encode(_getSettlementData(Constants.Q96))
            )
        );

        vm.expectRevert(bytes("ReentrancyGuard: reentrant call"));
        testSettlementReentrant.trade(tradeParams, settlementData);
    }
}
