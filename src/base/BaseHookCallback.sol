// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IPredyPool.sol";
import "../interfaces/IHooks.sol";

abstract contract BaseHookCallback is IHooks {
    IPredyPool immutable _predyPool;

    error CallerIsNotPredyPool();

    constructor(IPredyPool predyPool) {
        _predyPool = predyPool;
    }

    modifier onlyPredyPool() {
        if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();
        _;
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external virtual;
}
