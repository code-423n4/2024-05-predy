// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

struct GammaModifyInfo {
    bool isEnabled;
    uint64 expiration;
    int64 maximaDeviation;
    uint256 lowerLimit;
    uint256 upperLimit;
    uint32 hedgeInterval;
    uint32 sqrtPriceTrigger;
    uint32 minSlippageTolerance;
    uint32 maxSlippageTolerance;
    uint16 auctionPeriod;
    uint32 auctionRange;
}

library GammaModifyInfoLib {
    bytes internal constant GAMMA_MODIFY_INFO_TYPE = abi.encodePacked(
        "GammaModifyInfo(",
        "bool isEnabled,",
        "uint64 expiration,",
        "int64 maximaDeviation,",
        "uint256 lowerLimit,",
        "uint256 upperLimit,",
        "uint32 hedgeInterval,",
        "uint32 sqrtPriceTrigger,",
        "uint32 minSlippageTolerance,",
        "uint32 maxSlippageTolerance,",
        "uint16 auctionPeriod,",
        "uint32 auctionRange)"
    );

    bytes32 internal constant GAMMA_MODIFY_INFO_TYPE_HASH = keccak256(GAMMA_MODIFY_INFO_TYPE);

    /// @notice hash an GammaModifyInfo object
    /// @param info The GammaModifyInfo object to hash
    function hash(GammaModifyInfo memory info) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                GAMMA_MODIFY_INFO_TYPE_HASH,
                info.isEnabled,
                info.expiration,
                info.maximaDeviation,
                info.lowerLimit,
                info.upperLimit,
                info.hedgeInterval,
                info.sqrtPriceTrigger,
                info.minSlippageTolerance,
                info.maxSlippageTolerance,
                info.auctionPeriod,
                info.auctionRange
            )
        );
    }
}

struct GammaOrder {
    OrderInfo info;
    uint64 pairId;
    uint256 positionId;
    address entryTokenAddress;
    int256 quantity;
    int256 quantitySqrt;
    int256 marginAmount;
    uint256 baseSqrtPrice;
    uint32 slippageTolerance;
    uint8 leverage;
    GammaModifyInfo modifyInfo;
}

/// @notice helpers for handling general order objects
library GammaOrderLib {
    using OrderInfoLib for OrderInfo;

    bytes internal constant GAMMA_ORDER_TYPE = abi.encodePacked(
        "GammaOrder(",
        "OrderInfo info,",
        "uint64 pairId,",
        "uint256 positionId,",
        "address entryTokenAddress,",
        "int256 quantity,",
        "int256 quantitySqrt,",
        "int256 marginAmount,",
        "uint256 baseSqrtPrice,",
        "uint32 slippageTolerance,",
        "uint8 leverage,",
        "GammaModifyInfo modifyInfo)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec
    bytes internal constant ORDER_TYPE =
        abi.encodePacked(GAMMA_ORDER_TYPE, GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE, OrderInfoLib.ORDER_INFO_TYPE);
    bytes32 internal constant GAMMA_ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "GammaOrder witness)",
            GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE,
            GAMMA_ORDER_TYPE,
            OrderInfoLib.ORDER_INFO_TYPE,
            TOKEN_PERMISSIONS_TYPE
        )
    );

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(GammaOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                GAMMA_ORDER_TYPE_HASH,
                order.info.hash(),
                order.pairId,
                order.positionId,
                order.entryTokenAddress,
                order.quantity,
                order.quantitySqrt,
                order.marginAmount,
                order.baseSqrtPrice,
                order.slippageTolerance,
                order.leverage,
                GammaModifyInfoLib.hash(order.modifyInfo)
            )
        );
    }

    function resolve(GammaOrder memory gammaOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {
        uint256 amount = gammaOrder.marginAmount > 0 ? uint256(gammaOrder.marginAmount) : 0;

        return ResolvedOrder(gammaOrder.info, gammaOrder.entryTokenAddress, amount, hash(gammaOrder), sig);
    }
}
