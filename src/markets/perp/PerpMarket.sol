// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {PerpMarketV1} from "./PerpMarketV1.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {PerpOrderV3} from "./PerpOrderV3.sol";
import {OrderInfo} from "../../libraries/orders/OrderInfoLib.sol";
import {L2Decoder} from "../L2Decoder.sol";
import {Bps} from "../../libraries/math/Bps.sol";
import {DataType} from "../../libraries/DataType.sol";

struct PerpOrderV3L2 {
    address trader;
    uint256 nonce;
    uint256 quantity;
    uint256 marginAmount;
    uint256 limitPrice;
    uint256 stopPrice;
    bytes32 data1;
    bytes auctionData;
}

/**
 * @notice Perp market contract for Layer2.
 * Optimizing calldata size in this contract since L2 calldata is relatively expensive.
 */
contract PerpMarket is PerpMarketV1 {
    function executeOrderV3L2(
        PerpOrderV3L2 memory compressedOrder,
        bytes memory sig,
        SettlementParamsV3 memory settlementParams,
        uint64 orderId
    ) external nonReentrant returns (IPredyPool.TradeResult memory) {
        (uint64 deadline, uint64 pairId, uint8 leverage, bool reduceOnly, bool closePosition, bool side) =
            L2Decoder.decodePerpOrderV3Params(compressedOrder.data1);

        PerpOrderV3 memory order = PerpOrderV3({
            info: OrderInfo(address(this), compressedOrder.trader, compressedOrder.nonce, deadline),
            pairId: pairId,
            entryTokenAddress: _quoteTokenMap[pairId],
            side: side ? "Buy" : "Sell",
            quantity: compressedOrder.quantity,
            marginAmount: compressedOrder.marginAmount,
            limitPrice: compressedOrder.limitPrice,
            stopPrice: compressedOrder.stopPrice,
            leverage: leverage,
            reduceOnly: reduceOnly,
            closePosition: closePosition,
            auctionData: compressedOrder.auctionData
        });

        return _executeOrderV3(order, sig, settlementParams, orderId);
    }
}
