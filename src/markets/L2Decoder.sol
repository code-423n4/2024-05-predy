// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library L2Decoder {
    function decodeSpotOrderParams(bytes32 args1, bytes32 args2)
        internal
        pure
        returns (
            bool isLimit,
            uint64 startTime,
            uint64 endTime,
            uint64 deadline,
            uint128 startAmount,
            uint128 endAmount
        )
    {
        uint32 isLimitUint;

        assembly {
            deadline := and(args1, 0xFFFFFFFFFFFFFFFF)
            startTime := and(shr(64, args1), 0xFFFFFFFFFFFFFFFF)
            endTime := and(shr(128, args1), 0xFFFFFFFFFFFFFFFF)
            isLimitUint := and(shr(192, args1), 0xFFFFFFFF)
        }

        if (isLimitUint == 1) {
            isLimit = true;
        } else {
            isLimit = false;
        }

        assembly {
            startAmount := and(args2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            endAmount := and(shr(128, args2), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    function decodePerpOrderParams(bytes32 args)
        internal
        pure
        returns (uint64 deadline, uint64 pairId, uint8 leverage)
    {
        assembly {
            deadline := and(args, 0xFFFFFFFFFFFFFFFF)
            pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)
            leverage := and(shr(128, args), 0xFF)
        }
    }

    function decodePerpOrderV3Params(bytes32 args)
        internal
        pure
        returns (uint64 deadline, uint64 pairId, uint8 leverage, bool reduceOnly, bool closePosition, bool side)
    {
        uint8 reduceOnlyUint;
        uint8 closePositionUint;
        uint8 sideUint;

        assembly {
            deadline := and(args, 0xFFFFFFFFFFFFFFFF)
            pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)
            leverage := and(shr(128, args), 0xFF)
            reduceOnlyUint := and(shr(136, args), 0xFF)
            closePositionUint := and(shr(144, args), 0xFF)
            sideUint := and(shr(152, args), 0xFF)
        }

        reduceOnly = reduceOnlyUint == 1;
        closePosition = closePositionUint == 1;
        side = sideUint == 1;
    }
}
