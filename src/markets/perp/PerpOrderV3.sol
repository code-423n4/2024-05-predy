// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

struct PerpOrderV3 {
    OrderInfo info;
    uint64 pairId;
    address entryTokenAddress;
    string side;
    uint256 quantity;
    uint256 marginAmount;
    uint256 limitPrice;
    uint256 stopPrice;
    uint8 leverage;
    bool reduceOnly;
    bool closePosition;
    bytes auctionData;
}

/// @notice helpers for handling general order objects
library PerpOrderV3Lib {
    using OrderInfoLib for OrderInfo;

    bytes internal constant PERP_ORDER_V3_TYPE = abi.encodePacked(
        "PerpOrderV3(",
        "OrderInfo info,",
        "uint64 pairId,",
        "address entryTokenAddress,",
        "string side,",
        "uint256 quantity,",
        "uint256 marginAmount,",
        "uint256 limitPrice,",
        "uint256 stopPrice,",
        "uint8 leverage,",
        "bool reduceOnly,",
        "bool closePosition,",
        "bytes auctionData)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec
    bytes internal constant ORDER_V3_TYPE = abi.encodePacked(PERP_ORDER_V3_TYPE, OrderInfoLib.ORDER_INFO_TYPE);
    bytes32 internal constant PERP_ORDER_V3_TYPE_HASH = keccak256(ORDER_V3_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "PerpOrderV3 witness)", OrderInfoLib.ORDER_INFO_TYPE, PERP_ORDER_V3_TYPE, TOKEN_PERMISSIONS_TYPE
        )
    );

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(PerpOrderV3 memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PERP_ORDER_V3_TYPE_HASH,
                order.info.hash(),
                order.pairId,
                order.entryTokenAddress,
                keccak256(bytes(order.side)),
                order.quantity,
                order.marginAmount,
                order.limitPrice,
                order.stopPrice,
                order.leverage,
                order.reduceOnly,
                order.closePosition,
                keccak256(order.auctionData)
            )
        );
    }

    function resolve(PerpOrderV3 memory perpOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {
        return ResolvedOrder(perpOrder.info, perpOrder.entryTokenAddress, perpOrder.marginAmount, hash(perpOrder), sig);
    }
}
