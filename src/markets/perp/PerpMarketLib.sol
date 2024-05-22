// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {Constants} from "../../libraries/Constants.sol";
import {DecayLib} from "../../libraries/orders/DecayLib.sol";
import {Bps} from "../../libraries/math/Bps.sol";
import {Math} from "../../libraries/math/Math.sol";

library PerpMarketLib {
    error LimitPriceDoesNotMatch();

    error StopPriceDoesNotMatch();

    error LimitStopOrderDoesNotMatch();

    error MarketOrderDoesNotMatch();

    struct AuctionParams {
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
    }

    function getFinalTradeAmount(
        int256 currentPositionAmount,
        string memory side,
        uint256 quantity,
        bool reduceOnly,
        bool closePosition
    ) internal pure returns (int256 finalTradeAmount) {
        bool isLong = (keccak256(bytes(side))) == keccak256(bytes("Buy"));

        int256 tradeAmount = isLong ? int256(quantity) : -int256(quantity);

        if (closePosition) {
            if (isLong && currentPositionAmount >= 0) {
                return 0;
            }

            if (!isLong && currentPositionAmount <= 0) {
                return 0;
            }

            return -currentPositionAmount;
        }

        if (reduceOnly) {
            if (currentPositionAmount == 0) {
                return 0;
            }

            if (currentPositionAmount > 0) {
                if (tradeAmount < 0) {
                    if (currentPositionAmount > -tradeAmount) {
                        return tradeAmount;
                    } else {
                        return -currentPositionAmount;
                    }
                } else {
                    return 0;
                }
            } else {
                if (tradeAmount > 0) {
                    if (-currentPositionAmount > tradeAmount) {
                        return tradeAmount;
                    } else {
                        return -currentPositionAmount;
                    }
                } else {
                    return 0;
                }
            }
        }

        return tradeAmount;
    }

    function validateTrade(
        IPredyPool.TradeResult memory tradeResult,
        int256 tradeAmount,
        uint256 limitPrice,
        uint256 stopPrice,
        bytes memory auctionData
    ) internal view {
        uint256 tradePrice = Math.abs(tradeResult.payoff.perpEntryUpdate + tradeResult.payoff.perpPayoff)
            * Constants.Q96 / Math.abs(tradeAmount);

        uint256 oraclePrice = Math.calSqrtPriceToPrice(tradeResult.sqrtTwap);

        if (limitPrice == 0 && stopPrice == 0) {
            // market order
            if (!validateMarketOrder(tradePrice, tradeAmount, auctionData)) {
                revert MarketOrderDoesNotMatch();
            }
        } else if (limitPrice > 0 && stopPrice > 0) {
            // limit & stop order
            if (
                !validateLimitPrice(tradePrice, tradeAmount, limitPrice)
                    && !validateStopPrice(oraclePrice, tradePrice, tradeAmount, stopPrice, auctionData)
            ) {
                revert LimitStopOrderDoesNotMatch();
            }
        } else if (limitPrice > 0) {
            // limit order
            if (!validateLimitPrice(tradePrice, tradeAmount, limitPrice)) {
                revert LimitPriceDoesNotMatch();
            }
        } else if (stopPrice > 0) {
            // stop order
            if (!validateStopPrice(oraclePrice, tradePrice, tradeAmount, stopPrice, auctionData)) {
                revert StopPriceDoesNotMatch();
            }
        }
    }

    function validateLimitPrice(uint256 tradePrice, int256 tradeAmount, uint256 limitPrice)
        internal
        pure
        returns (bool)
    {
        if (tradeAmount == 0) {
            return false;
        }

        if (tradeAmount > 0 && limitPrice < tradePrice) {
            return false;
        }

        if (tradeAmount < 0 && limitPrice > tradePrice) {
            return false;
        }

        return true;
    }

    function validateStopPrice(
        uint256 oraclePrice,
        uint256 tradePrice,
        int256 tradeAmount,
        uint256 stopPrice,
        bytes memory auctionData
    ) internal pure returns (bool) {
        AuctionParams memory auctionParams = abi.decode(auctionData, (AuctionParams));

        uint256 decayedSlippageTorelance = DecayLib.decay2(
            auctionParams.startPrice,
            auctionParams.endPrice,
            auctionParams.startTime,
            auctionParams.endTime,
            ratio(oraclePrice, stopPrice)
        );

        if (tradeAmount > 0) {
            // buy
            if (stopPrice > oraclePrice) {
                return false;
            }

            if (tradePrice > Bps.upper(oraclePrice, decayedSlippageTorelance)) {
                return false;
            }
        } else if (tradeAmount < 0) {
            // sell
            if (stopPrice < oraclePrice) {
                return false;
            }

            if (tradePrice < Bps.lower(oraclePrice, decayedSlippageTorelance)) {
                return false;
            }
        }

        return true;
    }

    function ratio(uint256 price1, uint256 price2) internal pure returns (uint256) {
        if (price1 == price2) {
            return 0;
        } else if (price1 > price2) {
            return (price1 - price2) * Bps.ONE / price2;
        } else {
            return (price2 - price1) * Bps.ONE / price2;
        }
    }

    function validateMarketOrder(uint256 tradePrice, int256 tradeAmount, bytes memory auctionData)
        internal
        view
        returns (bool)
    {
        AuctionParams memory auctionParams = abi.decode(auctionData, (AuctionParams));

        uint256 decayedPrice = DecayLib.decay(
            auctionParams.startPrice, auctionParams.endPrice, auctionParams.startTime, auctionParams.endTime
        );

        if (tradeAmount != 0) {
            if (tradeAmount > 0 && decayedPrice < tradePrice) {
                return false;
            }

            if (tradeAmount < 0 && decayedPrice > tradePrice) {
                return false;
            }
        }

        return true;
    }
}
