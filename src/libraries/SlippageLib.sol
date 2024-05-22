// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {Constants} from "./Constants.sol";
import {Bps} from "./math/Bps.sol";
import {Math} from "./math/Math.sol";

library SlippageLib {
    using Bps for uint256;

    // 1.5% scaled by 1e8
    uint256 public constant MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 100747209;

    error InvalidAveragePrice();

    error SlippageTooLarge();

    error OutOfAcceptablePriceRange();

    function checkPrice(
        uint256 sqrtBasePrice,
        IPredyPool.TradeResult memory tradeResult,
        uint256 slippageTolerance,
        uint256 maxAcceptableSqrtPriceRange
    ) internal pure {
        uint256 basePrice = Math.calSqrtPriceToPrice(sqrtBasePrice);

        if (tradeResult.averagePrice == 0) {
            revert InvalidAveragePrice();
        }

        if (tradeResult.averagePrice > 0) {
            // short
            if (basePrice.lower(slippageTolerance) > uint256(tradeResult.averagePrice)) {
                revert SlippageTooLarge();
            }
        } else if (tradeResult.averagePrice < 0) {
            // long
            if (basePrice.upper(slippageTolerance) < uint256(-tradeResult.averagePrice)) {
                revert SlippageTooLarge();
            }
        }

        if (
            maxAcceptableSqrtPriceRange > 0
                && (
                    tradeResult.sqrtPrice < sqrtBasePrice * 1e8 / maxAcceptableSqrtPriceRange
                        || sqrtBasePrice * maxAcceptableSqrtPriceRange / 1e8 < tradeResult.sqrtPrice
                )
        ) {
            revert OutOfAcceptablePriceRange();
        }
    }
}
