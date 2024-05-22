// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IPredyPool.sol";
import "../interfaces/IHooks.sol";

abstract contract BaseHookCallbackUpgradable is Initializable, IHooks {
    IPredyPool _predyPool;

    error CallerIsNotPredyPool();

    constructor() {}

    modifier onlyPredyPool() {
        if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();
        _;
    }

    function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {
        _predyPool = predyPool;
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external virtual;
}
