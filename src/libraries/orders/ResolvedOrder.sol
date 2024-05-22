// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo} from "./OrderInfoLib.sol";

struct ResolvedOrder {
    OrderInfo info;
    address token;
    uint256 amount;
    bytes32 hash;
    bytes sig;
}

library ResolvedOrderLib {
    /// @notice thrown when the order targets a different market contract
    error InvalidMarket();

    /// @notice thrown if the order has expired
    error DeadlinePassed();

    /// @notice Validates a resolved order, reverting if invalid
    /// @param resolvedOrder resovled order
    function validate(ResolvedOrder memory resolvedOrder) internal view {
        if (address(this) != address(resolvedOrder.info.market)) {
            revert InvalidMarket();
        }

        if (block.timestamp > resolvedOrder.info.deadline) {
            revert DeadlinePassed();
        }
    }
}
