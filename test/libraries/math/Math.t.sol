// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/libraries/math/Math.sol";

contract MathTest is Test {
    uint256 internal constant _Q128 = 0x100000000000000000000000000000000;

    function testAbs(uint256 _x) public {
        uint256 expected = bound(_x, 0, uint256(type(int256).max));

        int256 p = int256(expected);
        int256 n = -int256(expected);

        assertEq(Math.abs(p), expected);
        assertEq(Math.abs(n), expected);
    }

    function testMax(uint256 _x) public {
        assertGe(Math.max(100, _x), 100);
    }

    function testMin(uint256 _x) public {
        assertLe(Math.min(100, _x), 100);
    }

    function testMulDivDownInt256() public {
        assertEq(Math.mulDivDownInt256(111, 111, 2), 6160);
        assertEq(Math.mulDivDownInt256(-111, 111, 2), -6161);
    }

    function testFullMulDivDownInt256() public {
        assertEq(Math.fullMulDivDownInt256(111, 111, 2), 6160);
        assertEq(Math.fullMulDivDownInt256(-111, 111, 2), -6161);
    }

    function testFullMulDivDownInt256Fuzz(uint256 _x) public {
        assertGe(Math.fullMulDivDownInt256(111, _x, _Q128), 0);
        assertLe(Math.fullMulDivDownInt256(-111, _x, _Q128), 0);
    }

    function testAddDelta(uint256 x, int256 y) public {
        x = bound(x, 0, type(uint128).max);
        y = bound(y, 0, type(int128).max);

        if (y >= 0) {
            assertEq(Math.addDelta(x, y), x + uint256(y));
        } else if (uint256(-y) <= x) {
            assertEq(Math.addDelta(x, y), x - uint256(-y));
        } else {
            vm.expectRevert();
            Math.addDelta(x, y);
        }
    }
}
