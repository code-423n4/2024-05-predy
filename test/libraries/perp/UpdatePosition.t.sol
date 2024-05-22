// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./Setup.t.sol";
import "../../../src/interfaces/IPredyPool.sol";

contract TestPerpUpdatePosition is TestPerp {
    Perp.UserStatus internal userStatus2;

    function setUp() public override {
        TestPerp.setUp();

        userStatus2 = Perp.createPerpUserStatus(1);

        Perp.updatePosition(
            pairStatus, userStatus2, Perp.UpdatePerpParams(100, -100), Perp.UpdateSqrtPerpParams(100, -100)
        );
    }

    // Cannot open position if there is no enough supply
    function testCannotOpenLong() public {
        vm.expectRevert(bytes("S0"));
        Perp.updatePosition(pairStatus, userStatus, Perp.UpdatePerpParams(1e18, -1e18), Perp.UpdateSqrtPerpParams(0, 0));
    }

    // Opens long position
    function testOpenLong(uint256 x) public {
        x = bound(x, 0, 2 * 1e12);
        int256 baseAmount = int256(x) - 1e12;

        int256 quoteAmount = -baseAmount;

        if (quoteAmount < -99999999) {
            vm.expectRevert(bytes("S0"));
        } else if (baseAmount < -99999999) {
            vm.expectRevert(bytes("S0"));
        }
        Perp.updatePosition(
            pairStatus, userStatus, Perp.UpdatePerpParams(baseAmount, quoteAmount), Perp.UpdateSqrtPerpParams(0, 0)
        );

        assertEq(userStatus.perp.amount, baseAmount);
        assertEq(userStatus.perp.entryValue, quoteAmount);
        assertEq(userStatus.sqrtPerp.amount, 0);
        assertEq(userStatus.sqrtPerp.entryValue, 0);
    }

    // Closes long position
    function testCloseLong() public {
        IPredyPool.Payoff memory payoff = Perp.updatePosition(
            pairStatus, userStatus2, Perp.UpdatePerpParams(-100, 200), Perp.UpdateSqrtPerpParams(0, 0)
        );

        assertEq(payoff.perpPayoff, 100);
        assertEq(payoff.sqrtPayoff, 0);
        assertEq(userStatus2.perp.amount, 0);
        assertEq(userStatus2.perp.entryValue, 0);
    }

    function testCloseSqrtLong() public {
        IPredyPool.Payoff memory payoff = Perp.updatePosition(
            pairStatus, userStatus2, Perp.UpdatePerpParams(0, 0), Perp.UpdateSqrtPerpParams(-100, 200)
        );

        assertEq(payoff.perpPayoff, 0);
        assertEq(payoff.sqrtPayoff, 100);
        assertEq(userStatus2.sqrtPerp.amount, 0);
        assertEq(userStatus2.sqrtPerp.entryValue, 0);
    }

    function testCloseLongPartially() public {
        IPredyPool.Payoff memory payoff = Perp.updatePosition(
            pairStatus, userStatus2, Perp.UpdatePerpParams(-50, 100), Perp.UpdateSqrtPerpParams(0, 0)
        );

        assertEq(payoff.perpPayoff, 50);
        assertEq(payoff.sqrtPayoff, 0);
        assertEq(userStatus2.perp.amount, 50);
        assertEq(userStatus2.perp.entryValue, -50);
    }

    function testCloseLongAndOpenShort() public {
        IPredyPool.Payoff memory payoff = Perp.updatePosition(
            pairStatus, userStatus2, Perp.UpdatePerpParams(-200, 400), Perp.UpdateSqrtPerpParams(0, 0)
        );

        assertEq(payoff.perpPayoff, 100);
        assertEq(payoff.sqrtPayoff, 0);
        assertEq(userStatus2.perp.amount, -100);
        assertEq(userStatus2.perp.entryValue, 200);
    }

    // Opens gamma short position
    function testOpenGammaShort() public {
        IPredyPool.Payoff memory payoff = Perp.updatePosition(
            pairStatus, userStatus, Perp.UpdatePerpParams(-1e6, 1e6), Perp.UpdateSqrtPerpParams(1e6, -2 * 1e6)
        );

        assertEq(payoff.perpPayoff, 0);
        assertEq(payoff.sqrtPayoff, 0);
        assertEq(userStatus2.perp.amount, 100);
        assertEq(userStatus2.perp.entryValue, -100);
    }
}
