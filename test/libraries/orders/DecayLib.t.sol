// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../../src/libraries/orders/DecayLib.sol";

contract DecayLibTest is Test {
    function testDecay() public {
        vm.warp(150);

        assertEq(DecayLib.decay(100, 200, 200, 250), 100);
        assertEq(DecayLib.decay(100, 200, 150, 200), 100);
        assertEq(DecayLib.decay(100, 200, 100, 200), 150);
        assertEq(DecayLib.decay(100, 200, 100, 150), 200);
        assertEq(DecayLib.decay(100, 200, 50, 100), 200);
    }
}
