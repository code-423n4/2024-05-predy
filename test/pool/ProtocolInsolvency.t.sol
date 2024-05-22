// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TestPool} from "./Setup.t.sol";
import {TestTradeMarket} from "../mocks/TestTradeMarket.sol";
import {IPredyPool} from "../../src/interfaces/IPredyPool.sol";
import {DataType} from "../../src/libraries/DataType.sol";
import {Constants} from "../../src/libraries/Constants.sol";
import {InterestRateModel} from "../../src/libraries/InterestRateModel.sol";

contract TestPoolProtocolInsolvency is TestPool {
    TestTradeMarket private tradeMarket;
    address private filler;

    function setUp() public override {
        TestPool.setUp();

        registerPair(address(currency1), address(0));

        predyPool.supply(1, true, 1e8);
        predyPool.supply(1, false, 1e8);

        tradeMarket = new TestTradeMarket(predyPool);

        currency1.transfer(address(tradeMarket), 1e10);

        currency0.approve(address(tradeMarket), 1e10);
        currency1.approve(address(tradeMarket), 1e10);

        predyPool.updateIRMParams(
            1,
            InterestRateModel.IRMParams(1e17, 9 * 1e17, 5 * 1e17, 1e18),
            InterestRateModel.IRMParams(1e17, 9 * 1e17, 5 * 1e17, 1e18)
        );
    }

    function testNormalFlow() external {
        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, 1e6, 0, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 1000);

        uint256 snapshot = vm.snapshot();

        vm.warp(block.timestamp + 1 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, -1e6, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 10100 / 10000)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 0);
        assertEq(currency1.balanceOf(address(predyPool)), 1);

        vm.revertTo(snapshot);

        vm.warp(block.timestamp + 7 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, -1e6, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 10100 / 10000)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 0);
        assertEq(currency1.balanceOf(address(predyPool)), 1);
    }

    function testEarnTradeFeeFlow() external {
        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -1e8, 1e8, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 1e16);
        for (uint256 i = 0; i < 10; i++) {
            _movePrice(false, 2 * 1e16);
            _movePrice(true, 2 * 1e16);
        }
        _movePrice(false, 1e16);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, 1e8, -1e8, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 0);
        assertEq(currency1.balanceOf(address(predyPool)), 0);
    }

    function testReallocationFlow() external {
        assertFalse(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96)));

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -9 * 1e7, 1e8, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, 1e7, -1e7, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 5 * 1e16);

        // reallocation is happened
        assertTrue(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96 * 15000 / 10000)));

        vm.warp(block.timestamp + 100 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, -1e7, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 15000 / 10000)
        );

        _movePrice(false, 5 * 1e16);
        vm.warp(block.timestamp + 10 days);

        assertTrue(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96 * 9000 / 10000)));

        vm.warp(block.timestamp + 200 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 2, -1e7, 1e7, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, 1e8, -1e8, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 5);
        assertEq(currency1.balanceOf(address(predyPool)), 7);
    }

    function testReallocationEdgeFlow() external {
        assertFalse(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96)));

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -9 * 1e5, 1e6, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -9 * 1e5, 1e6, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 5 * 1e16);

        // reallocation is happened
        assertTrue(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96 * 15000 / 10000)));

        vm.warp(block.timestamp + 10 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 2, -1e5, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 15000 / 10000)
        );

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, -1e5, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 15000 / 10000)
        );

        _movePrice(false, 5 * 1e16);
        vm.warp(block.timestamp + 10 days);

        assertTrue(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96)));

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, 1e6, -1e6, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 2, 1e6, -1e6, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 4);
        assertEq(currency1.balanceOf(address(predyPool)), 3);
    }

    function testLiquidation() external {
        assertFalse(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96)));

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -1e8, 1e8, abi.encode(_getTradeAfterParams(3 * 1e6))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 5 * 1e16);

        // reallocation is happened
        assertTrue(tradeMarket.reallocate(1, _getSettlementData(Constants.Q96 * 15000 / 10000)));

        vm.warp(block.timestamp + 100 days);

        tradeMarket.execLiquidationCall(1, 1e18, _getSettlementData(Constants.Q96 * 11000 / 10000));

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        assertEq(currency0.balanceOf(address(predyPool)), 1);
        assertEq(currency1.balanceOf(address(predyPool)), 1);
    }

    function testCreatorFeeFlow() external {
        predyPool.updateFeeRatio(1, 4);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, 1e7, 0, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        vm.warp(block.timestamp + 10 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -2 * 1e7, 0, abi.encode(_getTradeAfterParams(1e7))),
            _getSettlementData(Constants.Q96)
        );

        _movePrice(true, 1000);

        vm.warp(block.timestamp + 7 days);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 1, -1e7, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 10100 / 10000)
        );
        tradeMarket.trade(
            IPredyPool.TradeParams(1, 2, 2 * 1e7, 0, abi.encode(_getTradeAfterParams(0))),
            _getSettlementData(Constants.Q96 * 10100 / 10000)
        );

        predyPool.withdraw(1, true, 1e18);
        predyPool.withdraw(1, false, 1e18);

        predyPool.withdrawCreatorRevenue(1, true);
        predyPool.withdrawProtocolRevenue(1, true);
        predyPool.withdrawCreatorRevenue(1, false);
        predyPool.withdrawProtocolRevenue(1, false);

        assertEq(currency0.balanceOf(address(predyPool)), 3);
        assertEq(currency1.balanceOf(address(predyPool)), 4);
    }
}
