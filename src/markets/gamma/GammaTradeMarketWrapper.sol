// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {GammaTradeMarketL2} from "./GammaTradeMarketL2.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {GammaOrder} from "./GammaOrder.sol";

/// @dev for testing purpose
contract GammaTradeMarketWrapper is GammaTradeMarketL2 {
    // execute trade
    function executeTrade(GammaOrder memory gammaOrder, bytes memory sig, SettlementParamsV3 memory settlementParams)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        return _executeTrade(gammaOrder, sig, settlementParams);
    }
}
