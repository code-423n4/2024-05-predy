// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SpotMarket} from "./SpotMarket.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {SpotOrder} from "./SpotOrder.sol";
import {OrderInfo} from "../../libraries/orders/OrderInfoLib.sol";
import {Math} from "../../libraries/math/Math.sol";
import {L2Decoder} from "../L2Decoder.sol";

struct SpotMarketOrder {
    address trader;
    uint256 nonce;
    uint256 deadline;
    address quoteToken;
    address baseToken;
    int256 baseTokenAmount;
    uint256 quoteTokenAmount;
    bytes auctionData;
}

struct SpotLimitOrder {
    address trader;
    uint256 nonce;
    uint256 deadline;
    address quoteToken;
    address baseToken;
    int256 baseTokenAmount;
    uint256 quoteTokenAmount;
    uint256 limitQuoteTokenAmount;
}

/**
 * @notice Spot market contract for Layer2.
 * Optimizing calldata size in this contract since L2 calldata is relatively expensive.
 */
contract SpotMarketL2 is SpotMarket {
    constructor(address permit2Address) SpotMarket(permit2Address) {}

    function executeMarketOrder(
        SpotMarketOrder memory marketOrder,
        bytes memory sig,
        SettlementParams memory settlementParams
    ) external returns (int256 quoteTokenAmount) {
        SpotOrder memory order = SpotOrder({
            info: OrderInfo(address(this), marketOrder.trader, marketOrder.nonce, marketOrder.deadline),
            quoteToken: marketOrder.quoteToken,
            baseToken: marketOrder.baseToken,
            baseTokenAmount: marketOrder.baseTokenAmount,
            quoteTokenAmount: marketOrder.quoteTokenAmount,
            limitQuoteTokenAmount: 0,
            auctionData: marketOrder.auctionData
        });

        return _executeOrder(order, sig, settlementParams);
    }

    function executeLimitOrder(
        SpotLimitOrder memory limitOrder,
        bytes memory sig,
        SettlementParams memory settlementParams
    ) external returns (int256 quoteTokenAmount) {
        SpotOrder memory order = SpotOrder({
            info: OrderInfo(address(this), limitOrder.trader, limitOrder.nonce, limitOrder.deadline),
            quoteToken: limitOrder.quoteToken,
            baseToken: limitOrder.baseToken,
            baseTokenAmount: limitOrder.baseTokenAmount,
            quoteTokenAmount: limitOrder.quoteTokenAmount,
            limitQuoteTokenAmount: limitOrder.limitQuoteTokenAmount,
            auctionData: bytes("")
        });

        return _executeOrder(order, sig, settlementParams);
    }
}
