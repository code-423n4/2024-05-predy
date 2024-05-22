// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../pool/Setup.t.sol";
import "../mocks/AttackCallbackContract.sol";

contract TestAttackCallback is TestPool {
    AttackCallbackContract _attackCountract;
    uint256 pairId;

    function setUp() public override {
        TestPool.setUp();

        pairId = registerPair(address(currency1), address(0), false);

        predyPool.supply(pairId, true, 1e8);
        predyPool.supply(pairId, false, 1e8);

        _attackCountract = new AttackCallbackContract(predyPool, address(currency1));
    }

    function testAttackCallback() public {
        assertEq(currency1.balanceOf(address(_attackCountract)), 0);

        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(pairId, 0, 0, 0, bytes("0x"));

        vm.expectRevert(bytes("ReentrancyGuard: reentrant call"));
        _attackCountract.trade(tradeParams);

        assertEq(currency1.balanceOf(address(_attackCountract)), 0);
    }
}
