// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/base/BaseHookCallback.sol";
import {IPredyPool} from "../../src/interfaces/IPredyPool.sol";

contract TestSettlementCurrencyNotSettled is BaseHookCallback {
    struct SettlementParams {
        address baseTokenAddress;
        address settleTokenAddress;
        int256 takeAmount;
        int256 settleAmount;
    }

    constructor(IPredyPool predyPool) BaseHookCallback(predyPool) {}

    function predySettlementCallback(address, address, bytes memory settlementData, int256) external {
        SettlementParams memory settlemendParams = abi.decode(settlementData, (SettlementParams));

        if (settlemendParams.takeAmount >= 0) {
            _predyPool.take(false, address(this), uint256(settlemendParams.takeAmount));
        } else {
            IERC20(settlemendParams.baseTokenAddress).transfer(
                address(_predyPool), uint256(-settlemendParams.takeAmount)
            );
        }

        if (settlemendParams.settleAmount >= 0) {
            _predyPool.take(true, address(this), uint256(settlemendParams.settleAmount));
        } else {
            IERC20(settlemendParams.settleTokenAddress).transfer(
                address(_predyPool), uint256(-settlemendParams.settleAmount)
            );
        }
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external override(BaseHookCallback) {}

    function trade(IPredyPool.TradeParams memory tradeParams, bytes memory data)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        return _predyPool.trade(tradeParams, data);
    }
}

contract TestSettlementReentrant is BaseHookCallback {
    struct SettlementParams {
        address settleTokenAddress;
        uint256 takeAmount;
        uint256 settleAmount;
        IPredyPool.TradeParams tradeParams;
        bytes settlementData;
    }

    constructor(IPredyPool predyPool) BaseHookCallback(predyPool) {}

    function predySettlementCallback(address, address, bytes memory settlementData, int256) external {
        SettlementParams memory settlemendParams = abi.decode(settlementData, (SettlementParams));

        _predyPool.take(false, address(this), settlemendParams.takeAmount);

        IERC20(settlemendParams.settleTokenAddress).transfer(address(_predyPool), settlemendParams.settleAmount);

        IPredyPool(address(_predyPool)).trade(settlemendParams.tradeParams, settlemendParams.settlementData);
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external override(BaseHookCallback) {}

    function trade(IPredyPool.TradeParams memory tradeParams, bytes memory data)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        return _predyPool.trade(tradeParams, data);
    }
}
