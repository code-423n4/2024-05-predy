// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/libraries/Perp.sol";

contract TestCalculateSqrtPerpOffset is Test {
    Perp.UserStatus internal userStatus;
    Perp.UserStatus internal longUserStatus;
    Perp.UserStatus internal shortUserStatus;

    function setUp() public virtual {
        userStatus = Perp.createPerpUserStatus(1);
        longUserStatus = Perp.createPerpUserStatus(1);
        shortUserStatus = Perp.createPerpUserStatus(1);

        longUserStatus.sqrtPerp.amount = 100;
        shortUserStatus.sqrtPerp.amount = -100;
    }

    function testZero() public {
        (int256 offsetUnderlying, int256 offsetStable) = Perp.calculateSqrtPerpOffset(userStatus, 100, 200, 0, false);

        assertEq(offsetUnderlying, 0);
        assertEq(offsetStable, 0);
    }

    function testOpenLong() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, 1000000, false);

        assertEq(offsetUnderlying, 990050);
        assertEq(offsetStable, 1005012);
    }

    function testOpenShort() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, -1000000, false);

        assertEq(offsetUnderlying, -990051);
        assertEq(offsetStable, -1005013);
    }

    function testCloseLong() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, -100000, false);

        assertEq(offsetUnderlying, -99006);
        assertEq(offsetStable, -100502);
    }

    function testCloseShort() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, 100000, false);

        assertEq(offsetUnderlying, 99005);
        assertEq(offsetStable, 100501);
    }

    function testCloseLongAndOpenShort() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, -1100000, false);

        assertEq(offsetUnderlying, -1089056);
        assertEq(offsetStable, -1105514);
    }

    function testCloseShortAndOpenLong() public {
        (int256 offsetUnderlying, int256 offsetStable) =
            Perp.calculateSqrtPerpOffset(userStatus, 100, 200, 110000, false);

        assertEq(offsetUnderlying, 108905);
        assertEq(offsetStable, 110551);
    }
}
