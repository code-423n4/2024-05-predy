// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TestPool} from "./Setup.t.sol";
import {IPredyPool} from "../../src/interfaces/IPredyPool.sol";

contract TestPoolSetOperator is TestPool {
    function setUp() public override {
        TestPool.setUp();
    }

    function testSetOperator() public {
        predyPool.setOperator(address(1));
    }

    function testCannotSetOperator() public {
        address notOperator = vm.addr(0x0002);

        vm.startPrank(notOperator);

        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        predyPool.setOperator(address(1));

        vm.stopPrank();
    }

    function testCannotSetOperatorIfAddressIsZero() public {
        vm.expectRevert();
        predyPool.setOperator(address(0));
    }
}
