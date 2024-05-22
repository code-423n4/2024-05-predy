// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import "../../src/lens/PredyPoolQuoter.sol";
import "../pool/Setup.t.sol";

contract TestLens is TestPool {
    function setUp() public virtual override(TestPool) {
        TestPool.setUp();

        registerPair(address(currency1), address(0));

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);
    }
}
