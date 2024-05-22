// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/PairLib.sol";

contract PairLibTest is Test {
    function testGetRebalanceCacheId() public {
        uint256 rebalanceCacheId = PairLib.getRebalanceCacheId(18 * 1e18, 18 * 1e18);

        assertEq(rebalanceCacheId, 332041393326771929088000000000000000000);
    }
}
