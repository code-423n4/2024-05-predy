// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../src/libraries/Constants.sol";

contract OrderValidatorUtils {
    function calculateLimitPrice(uint256 quoteAmount, uint256 baseAmount) internal pure returns (uint256) {
        return quoteAmount * Constants.Q96 / baseAmount;
    }

    function encodePerpOrderParams(uint64 deadline, uint64 pairId, uint8 leverage)
        internal
        pure
        returns (bytes32 params)
    {
        assembly {
            params := add(deadline, add(shl(64, pairId), shl(128, leverage)))
        }
    }

    function encodePerpOrderV3Params(
        uint64 deadline,
        uint64 pairId,
        uint8 leverage,
        bool reduceOnly,
        bool closePosition,
        bool side
    ) internal pure returns (bytes32 params) {
        uint8 reduceOnlyUint = reduceOnly ? 1 : 0;
        uint8 closePositionUint = closePosition ? 1 : 0;
        uint8 sideUint = side ? 1 : 0;

        assembly {
            params :=
                add(
                    deadline,
                    add(
                        shl(64, pairId),
                        add(
                            shl(128, leverage),
                            add(shl(136, reduceOnlyUint), add(shl(144, closePositionUint), shl(152, sideUint)))
                        )
                    )
                )
        }
    }

    function encodeParams(
        bool isLimit,
        uint64 startTime,
        uint64 endTime,
        uint64 deadline,
        uint128 startAmount,
        uint128 endAmount
    ) internal pure returns (bytes32 params1, bytes32 params2) {
        uint32 isLimitUint = isLimit ? 1 : 0;

        assembly {
            params1 := add(deadline, add(shl(64, startTime), add(shl(128, endTime), shl(192, isLimitUint))))
        }

        assembly {
            params2 := add(startAmount, shl(128, endAmount))
        }
    }

    function encodeGammaModifyParams(
        bool isEnabled,
        uint64 expiration,
        uint32 hedgeInterval,
        uint32 sqrtPriceTrigger,
        uint32 minSlippageTolerance,
        uint32 maxSlippageTolerance,
        uint16 auctionPeriod,
        uint32 auctionRange
    ) internal pure returns (bytes32 params) {
        uint32 isEnabledUint = isEnabled ? 1 : 0;

        assembly {
            params :=
                add(
                    expiration,
                    add(
                        shl(64, hedgeInterval),
                        add(
                            shl(96, sqrtPriceTrigger),
                            add(
                                shl(128, minSlippageTolerance),
                                add(
                                    shl(160, maxSlippageTolerance),
                                    add(shl(192, auctionRange), add(shl(224, isEnabledUint), shl(240, auctionPeriod)))
                                )
                            )
                        )
                    )
                )
        }
    }
}
