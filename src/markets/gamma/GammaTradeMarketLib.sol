// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Bps} from "../../libraries/math/Bps.sol";
import {Constants} from "../../libraries/Constants.sol";
import {DataType} from "../../libraries/DataType.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {SlippageLib} from "../../libraries/SlippageLib.sol";
import {GammaModifyInfo} from "./GammaOrder.sol";

library GammaTradeMarketLib {
    error TooShortHedgeInterval();

    struct UserPosition {
        uint256 vaultId;
        address owner;
        uint64 pairId;
        uint8 leverage;
        int64 maximaDeviation;
        uint256 expiration;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 lastHedgedTime;
        uint256 hedgeInterval;
        uint256 lastHedgedSqrtPrice;
        uint256 sqrtPriceTrigger;
        GammaTradeMarketLib.AuctionParams auctionParams;
    }

    struct AuctionParams {
        uint32 minSlippageTolerance;
        uint32 maxSlippageTolerance;
        uint16 auctionPeriod;
        uint32 auctionRange;
    }

    enum CallbackType {
        NONE,
        QUOTE,
        TRADE,
        CLOSE,
        HEDGE_BY_TIME,
        HEDGE_BY_PRICE,
        CLOSE_BY_TIME,
        CLOSE_BY_PRICE
    }

    function calculateDelta(uint256 _sqrtPrice, int64 maximaDeviation, int256 _sqrtAmount, int256 perpAmount)
        internal
        pure
        returns (int256)
    {
        int256 sqrtPrice = int256(_sqrtPrice) * (1e6 + maximaDeviation) / 1e6;

        // delta of 'x + 2 * sqrt(x)' is '1 + 1 / sqrt(x)'
        return perpAmount + _sqrtAmount * int256(Constants.Q96) / sqrtPrice;
    }

    function validateHedgeCondition(GammaTradeMarketLib.UserPosition memory userPosition, uint256 sqrtIndexPrice)
        external
        view
        returns (bool, uint256 slippageTolerance, GammaTradeMarketLib.CallbackType)
    {
        if (
            userPosition.hedgeInterval > 0
                && userPosition.lastHedgedTime + userPosition.hedgeInterval <= block.timestamp
        ) {
            return (
                true,
                calculateSlippageTolerance(
                    userPosition.lastHedgedTime + userPosition.hedgeInterval,
                    block.timestamp,
                    userPosition.auctionParams
                    ),
                GammaTradeMarketLib.CallbackType.HEDGE_BY_TIME
            );
        }

        // if sqrtPriceTrigger is 0, it means that the user doesn't want to use this feature
        if (userPosition.sqrtPriceTrigger == 0) {
            return (false, 0, GammaTradeMarketLib.CallbackType.NONE);
        }

        uint256 upperThreshold = userPosition.lastHedgedSqrtPrice * userPosition.sqrtPriceTrigger / Bps.ONE;
        uint256 lowerThreshold = userPosition.lastHedgedSqrtPrice * Bps.ONE / userPosition.sqrtPriceTrigger;

        if (lowerThreshold >= sqrtIndexPrice) {
            return (
                true,
                calculateSlippageToleranceByPrice(sqrtIndexPrice, lowerThreshold, userPosition.auctionParams),
                GammaTradeMarketLib.CallbackType.HEDGE_BY_PRICE
            );
        }

        if (upperThreshold <= sqrtIndexPrice) {
            return (
                true,
                calculateSlippageToleranceByPrice(upperThreshold, sqrtIndexPrice, userPosition.auctionParams),
                GammaTradeMarketLib.CallbackType.HEDGE_BY_PRICE
            );
        }

        return (false, 0, GammaTradeMarketLib.CallbackType.NONE);
    }

    function validateCloseCondition(UserPosition memory userPosition, uint256 sqrtIndexPrice)
        external
        view
        returns (bool, uint256 slippageTolerance, CallbackType)
    {
        if (userPosition.expiration <= block.timestamp) {
            return (
                true,
                calculateSlippageTolerance(userPosition.expiration, block.timestamp, userPosition.auctionParams),
                CallbackType.CLOSE_BY_TIME
            );
        }

        uint256 upperThreshold = userPosition.upperLimit;
        uint256 lowerThreshold = userPosition.lowerLimit;

        if (lowerThreshold > 0 && lowerThreshold >= sqrtIndexPrice) {
            return (
                true,
                calculateSlippageToleranceByPrice(sqrtIndexPrice, lowerThreshold, userPosition.auctionParams),
                CallbackType.CLOSE_BY_PRICE
            );
        }

        if (upperThreshold > 0 && upperThreshold <= sqrtIndexPrice) {
            return (
                true,
                calculateSlippageToleranceByPrice(upperThreshold, sqrtIndexPrice, userPosition.auctionParams),
                CallbackType.CLOSE_BY_PRICE
            );
        }

        return (false, 0, CallbackType.NONE);
    }

    function calculateSlippageTolerance(uint256 startTime, uint256 currentTime, AuctionParams memory auctionParams)
        internal
        pure
        returns (uint256)
    {
        if (currentTime <= startTime) {
            return auctionParams.minSlippageTolerance;
        }

        uint256 elapsed = (currentTime - startTime) * Bps.ONE / auctionParams.auctionPeriod;

        if (elapsed > Bps.ONE) {
            return auctionParams.maxSlippageTolerance;
        }

        return (
            auctionParams.minSlippageTolerance
                + elapsed * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance) / Bps.ONE
        );
    }

    /**
     * @notice Calculate slippage tolerance by price
     * trader want to trade in price1 >= price2,
     * slippage tolerance will be increased if price1 <= price2
     */
    function calculateSlippageToleranceByPrice(uint256 price1, uint256 price2, AuctionParams memory auctionParams)
        internal
        pure
        returns (uint256)
    {
        if (price2 <= price1) {
            return auctionParams.minSlippageTolerance;
        }

        uint256 ratio = (price2 * Bps.ONE / price1 - Bps.ONE);

        if (ratio > auctionParams.auctionRange) {
            return auctionParams.maxSlippageTolerance;
        }

        return (
            auctionParams.minSlippageTolerance
                + ratio * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance)
                    / auctionParams.auctionRange
        );
    }

    function saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)
        external
        returns (bool)
    {
        if (!modifyInfo.isEnabled) {
            return false;
        }

        if (0 < modifyInfo.hedgeInterval && 10 minutes > modifyInfo.hedgeInterval) {
            revert TooShortHedgeInterval();
        }

        require(modifyInfo.maxSlippageTolerance >= modifyInfo.minSlippageTolerance);
        require(modifyInfo.maxSlippageTolerance <= 2 * Bps.ONE);
        require(-1e6 < modifyInfo.maximaDeviation && modifyInfo.maximaDeviation < 1e6);

        // auto close condition
        userPosition.expiration = modifyInfo.expiration;
        userPosition.lowerLimit = modifyInfo.lowerLimit;
        userPosition.upperLimit = modifyInfo.upperLimit;

        // auto hedge condition
        userPosition.maximaDeviation = modifyInfo.maximaDeviation;
        userPosition.hedgeInterval = modifyInfo.hedgeInterval;
        userPosition.sqrtPriceTrigger = modifyInfo.sqrtPriceTrigger;
        userPosition.auctionParams.minSlippageTolerance = modifyInfo.minSlippageTolerance;
        userPosition.auctionParams.maxSlippageTolerance = modifyInfo.maxSlippageTolerance;
        userPosition.auctionParams.auctionPeriod = modifyInfo.auctionPeriod;
        userPosition.auctionParams.auctionRange = modifyInfo.auctionRange;

        return true;
    }
}
