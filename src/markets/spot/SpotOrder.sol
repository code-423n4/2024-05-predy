// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";
import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

struct SpotOrder {
    OrderInfo info;
    address quoteToken;
    address baseToken;
    int256 baseTokenAmount;
    uint256 quoteTokenAmount;
    uint256 limitQuoteTokenAmount;
    bytes auctionData;
}

/// @notice helpers for handling predict order objects
library SpotOrderLib {
    using OrderInfoLib for OrderInfo;

    bytes internal constant SPOT_ORDER_TYPE = abi.encodePacked(
        "SpotOrder(",
        "OrderInfo info,",
        "address quoteToken,",
        "address baseToken,",
        "int256 baseTokenAmount,",
        "uint256 quoteTokenAmount,",
        "uint256 limitQuoteTokenAmount,",
        "bytes auctionData)"
    );

    bytes internal constant ORDER_TYPE = abi.encodePacked(SPOT_ORDER_TYPE, OrderInfoLib.ORDER_INFO_TYPE);
    bytes32 internal constant SPOT_ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked("SpotOrder witness)", OrderInfoLib.ORDER_INFO_TYPE, SPOT_ORDER_TYPE, TOKEN_PERMISSIONS_TYPE)
    );

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(SpotOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                SPOT_ORDER_TYPE_HASH,
                order.info.hash(),
                order.quoteToken,
                order.baseToken,
                order.baseTokenAmount,
                order.quoteTokenAmount,
                order.limitQuoteTokenAmount,
                keccak256(order.auctionData)
            )
        );
    }

    function resolve(SpotOrder memory spotOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {
        uint256 amount;
        address token;

        if (spotOrder.baseTokenAmount > 0) {
            token = spotOrder.quoteToken;
            amount = spotOrder.quoteTokenAmount;
        } else {
            token = spotOrder.baseToken;
            amount = uint256(-spotOrder.baseTokenAmount);
        }

        return ResolvedOrder(spotOrder.info, token, amount, hash(spotOrder), sig);
    }
}
