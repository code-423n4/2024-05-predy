// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../mocks/TestTradeMarket.sol";
import {SlippageLib} from "../../src/libraries/SlippageLib.sol";

contract TestExecLiquidationCall is TestPool {
    TestTradeMarket _tradeMarket;
    address filler;

    function setUp() public override {
        TestPool.setUp();

        registerPair(address(currency1), address(0));

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

        _tradeMarket = new TestTradeMarket(predyPool);

        filler = vm.addr(5);

        currency0.transfer(address(_tradeMarket), 1e10);
        currency1.transfer(address(_tradeMarket), 1e10);

        currency0.approve(address(_tradeMarket), 1e10);
        currency1.approve(address(_tradeMarket), 1e10);

        currency0.mint(filler, 1e10);
        currency1.mint(filler, 1e10);
        vm.startPrank(filler);
        currency0.approve(address(_tradeMarket), 1e10);
        currency1.approve(address(_tradeMarket), 1e10);
        vm.stopPrank();
    }

    function checkMarginEqZero(uint256 vaultId) internal {
        DataType.Vault memory vault = predyPool.getVault(vaultId);
        assertEq(vault.margin, 0);
    }

    function checkMarginGtZero(uint256 vaultId) internal {
        DataType.Vault memory vault = predyPool.getVault(vaultId);
        assertGt(vault.margin, 0);
    }

    // liquidate succeeds if the vault is danger
    function testLiquidateSucceedsIfVaultIsDanger(uint256 closeRatio) public {
        closeRatio = bound(closeRatio, 1e17, 1e18);

        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -4 * 1e8, 0, abi.encode(_getTradeAfterParams(1e8)));

        _tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        _movePrice(true, 6 * 1e16);

        vm.warp(block.timestamp + 30 minutes);

        uint256 beforeMargin = currency1.balanceOf(address(_tradeMarket));
        _tradeMarket.execLiquidationCall(1, closeRatio, _getSettlementData(Constants.Q96 * 11000 / 10000));
        uint256 afterMargin = currency1.balanceOf(address(_tradeMarket));

        if (closeRatio == 1e18) {
            assertGt(afterMargin - beforeMargin, 0);
        } else {
            checkMarginGtZero(1);
        }
    }

    // liquidate fails if slippage too large
    function testLiquidateFailIfSlippageTooLarge() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -4 * 1e8, 0, abi.encode(_getTradeAfterParams(1e8)));

        _tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        _movePrice(true, 6 * 1e16);

        vm.warp(block.timestamp + 30 minutes);

        {
            IFillerMarket.SettlementParams memory settlementData = _getSettlementData(2 * Constants.Q96);

            vm.expectRevert(SlippageLib.SlippageTooLarge.selector);
            _tradeMarket.execLiquidationCall(1, 1e18, settlementData);
        }
    }

    // liquidate succeeds by premium payment
    function testLiquidateSucceedsByPremiumPayment() public {
        _tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -2 * 1e8, 2 * 1e8, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(1e4)
        );

        _tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, 1e8, -1e8, abi.encode(_getTradeAfterParams(1e6))), _getSettlementData(1e4)
        );

        _movePrice(true, 2 * 1e16);
        _movePrice(false, 2 * 1e16);

        vm.warp(block.timestamp + 10 minutes);

        int256 baseAmount = _predyPoolQuoter.quoteLiquidation(2, 1e18);

        assertEq(baseAmount, -257);

        _tradeMarket.execLiquidationCall(2, 1e18, _getSettlementData(Constants.Q96 * 9000 / 10000));

        checkMarginEqZero(2);
    }

    // liquidate succeeds with insolvent vault
    function testLiquidateSucceedsWithInsolvent() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -48 * 1e7, 0, abi.encode(_getTradeAfterParams(1e8)));

        _tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        _movePrice(true, 8 * 1e16);

        vm.warp(block.timestamp + 1 minutes);

        _movePrice(true, 2 * 1e16);

        vm.warp(block.timestamp + 29 minutes);

        // check insolvency
        IPredyPool.VaultStatus memory vaultStatus = _predyPoolQuoter.quoteVaultStatus(1);
        assertLt(vaultStatus.vaultValue, vaultStatus.minMargin);
        assertLt(vaultStatus.vaultValue, 0);

        IFillerMarket.SettlementParams memory settlementParams =
            _getDebugSettlementData(Constants.Q96 * 12300 / 10000, 6 * 1e8);

        vm.expectRevert(bytes("TRANSFER_FROM_FAILED"));
        _tradeMarket.execLiquidationCall(1, 1e18, settlementParams);

        _tradeMarket.execLiquidationCall(1, 1e18, _getDebugSettlementData(Constants.Q96 * 10300 / 10000, 6 * 1e8));

        checkMarginEqZero(1);
    }

    // liquidate fails if the vault is safe
    function testLiquidateFailsIfVaultIsSafe() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -4 * 1e8, 0, abi.encode(_getTradeAfterParams(1e8)));

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96);

        _tradeMarket.trade(tradeParams, settlementData);

        vm.expectRevert(abi.encodeWithSelector(IPredyPool.VaultIsNotDanger.selector, 99960001, 80007996));
        _tradeMarket.execLiquidationCall(1, 1e18, settlementData);
    }

    // liquidate fails after liquidation
    function testLiquidateFailsAfterLiquidation() public {
        IPredyPool.TradeParams memory tradeParams =
            IPredyPool.TradeParams(1, 0, -4 * 1e8, 0, abi.encode(_getTradeAfterParams(1e8)));

        _tradeMarket.trade(tradeParams, _getSettlementData(Constants.Q96));

        _movePrice(true, 6 * 1e16);

        vm.warp(block.timestamp + 30 minutes);

        IFillerMarket.SettlementParams memory settlementData = _getSettlementData(Constants.Q96 * 11000 / 10000);

        _tradeMarket.execLiquidationCall(1, 1e18, settlementData);

        vm.expectRevert(abi.encodeWithSelector(IPredyPool.VaultIsNotDanger.selector, 0, 0));
        _tradeMarket.execLiquidationCall(1, 1e18, settlementData);
    }
}
