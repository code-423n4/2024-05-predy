// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct OrderInfo {
    address market;
    address trader;
    uint256 nonce;
    uint256 deadline;
}

/// @notice helpers for handling OrderInfo objects
library OrderInfoLib {
    bytes internal constant ORDER_INFO_TYPE = "OrderInfo(address market,address trader,uint256 nonce,uint256 deadline)";
    bytes32 internal constant ORDER_INFO_TYPE_HASH = keccak256(ORDER_INFO_TYPE);

    /// @notice hash an OrderInfo object
    /// @param info The OrderInfo object to hash
    function hash(OrderInfo memory info) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORDER_INFO_TYPE_HASH, info.market, info.trader, info.nonce, info.deadline));
    }
}
