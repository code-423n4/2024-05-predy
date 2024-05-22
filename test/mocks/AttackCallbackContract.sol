// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import "../../src/interfaces/IPredyPool.sol";
import "../../src/PredyPool.sol";

/**
 * @notice A mock attack contract
 */
contract AttackCallbackContract {
    PredyPool private _predyPool;
    address private _token;

    constructor(PredyPool predyPool, address token) {
        _predyPool = predyPool;
        _token = token;
    }

    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external {}

    function predyTradeAfterCallback(IPredyPool.TradeParams memory, IPredyPool.TradeResult memory) external {
        _predyPool.take(true, address(this), 100);

        ERC20(_token).approve(address(_predyPool), 100);

        _predyPool.supply(1, true, 100);
    }

    function trade(IPredyPool.TradeParams memory tradeParams) external {
        _predyPool.trade(tradeParams, bytes("0x"));

        _predyPool.withdraw(1, true, 100);
    }
}
