// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library PairLib {
    function getRebalanceCacheId(uint256 pairId, uint64 rebalanceId) internal pure returns (uint256) {
        return pairId * type(uint64).max + rebalanceId;
    }
}
