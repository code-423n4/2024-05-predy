// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../mocks/TestTradeMarket.sol";
import {Constants} from "../../src/libraries/Constants.sol";

contract TestPoolWithdraw is TestPool {
    TestTradeMarket tradeMarket;
    address supplyTokenAddress;

    event TokenWithdrawn(address indexed account, uint256 pairId, bool isStable, uint256 finalWithdrawnAmount);

    function setUp() public override {
        TestPool.setUp();

        registerPair(address(currency1), address(0));

        DataType.PairStatus memory pair = predyPool.getPairStatus(1);

        supplyTokenAddress = pair.basePool.supplyTokenAddress;

        tradeMarket = new TestTradeMarket(predyPool);

        currency1.transfer(address(tradeMarket), 1e8);

        currency0.approve(address(predyPool), type(uint256).max);
        currency1.approve(address(predyPool), type(uint256).max);

        currency0.approve(address(tradeMarket), 1e8);
        currency1.approve(address(tradeMarket), 1e8);
    }

    // supply succeeds
    function testWithdraw(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);

        predyPool.supply(1, false, 1e6);

        uint256 beforeBalance = ERC20(currency0).balanceOf(address(this));

        uint256 finalWithdrawnAmount = amount < 1e6 ? amount : 1e6;

        vm.expectEmit(true, true, true, true);
        emit TokenWithdrawn(address(this), 1, false, finalWithdrawnAmount);
        predyPool.withdraw(1, false, amount);

        uint256 afterBalance = ERC20(currency0).balanceOf(address(this));

        assertEq(afterBalance - beforeBalance, finalWithdrawnAmount);

        assertEq(ERC20(supplyTokenAddress).balanceOf(address(this)), 1e6 - finalWithdrawnAmount);
    }

    // withdraw fails if utilization is high
    function testWithdrawIfBorrowed(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);

        predyPool.supply(1, true, 1e6);
        predyPool.supply(1, false, 1e6);

        tradeMarket.trade(
            IPredyPool.TradeParams(1, 0, -10000, 9000, abi.encode(_getTradeAfterParams(1e6))),
            _getSettlementData(Constants.Q96)
        );

        if (amount >= 998562) {
            vm.expectRevert(bytes("S0"));
        }
        predyPool.withdraw(1, false, amount);
    }

    // withdraw fails if pairId is 0
    function testWithdrawFailsIfPairIsZero() public {
        predyPool.supply(1, false, 1e6);

        vm.expectRevert(IPredyPool.InvalidPairId.selector);
        predyPool.withdraw(2, false, 1e6);
    }
}
