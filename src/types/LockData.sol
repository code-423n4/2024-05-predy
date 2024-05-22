// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IPredyPool.sol";

library LockDataLibrary {
    struct LockData {
        address locker;
        uint256 quoteReserve;
        uint256 baseReserve;
        uint256 pairId;
    }
}
