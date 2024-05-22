// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {GammaTradeMarket} from "../markets/gamma/GammaTradeMarket.sol";
import {GammaOrder} from "../markets/gamma/GammaOrder.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {IFillerMarket} from "../interfaces/IFillerMarket.sol";

/**
 * @notice Quoter contract for GammaTradeMarket
 */
contract GammaTradeMarketQuoter {
    GammaTradeMarket public gammaTradeMarket;

    constructor(GammaTradeMarket _gammaTradeMarket) {
        gammaTradeMarket = _gammaTradeMarket;
    }

    function quoteTrade(GammaOrder memory order, IFillerMarket.SettlementParamsV3 memory settlementData)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        try gammaTradeMarket.quoteTrade(order, settlementData) {}
        catch (bytes memory reason) {
            tradeResult = _parseRevertReason(reason);
        }
    }

    /// @notice Return the trade result of abi-encoded bytes.
    /// @param reason abi-encoded tradeResult
    function _parseRevertReason(bytes memory reason) private pure returns (IPredyPool.TradeResult memory tradeResult) {
        if (reason.length < 192) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (IPredyPool.TradeResult));
        }
    }
}
