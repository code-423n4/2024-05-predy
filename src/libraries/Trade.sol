// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {Constants} from "./Constants.sol";
import {DataType} from "./DataType.sol";
import {Perp} from "./Perp.sol";
import {PerpFee} from "./PerpFee.sol";
import {GlobalDataLibrary} from "../types/GlobalData.sol";
import {LockDataLibrary} from "../types/LockData.sol";
import {PositionCalculator} from "./PositionCalculator.sol";
import {Math} from "./math/Math.sol";
import {UniHelper} from "./UniHelper.sol";

library Trade {
    using GlobalDataLibrary for GlobalDataLibrary.GlobalData;
    using SafeCast for uint256;

    struct SwapStableResult {
        int256 amountPerp;
        int256 amountSqrtPerp;
        int256 fee;
        int256 averagePrice;
    }

    event Swapped(uint256 pairId, uint256 vaultId, address owner, int256 settledQuoteAmount, int256 settledBaseAmount);

    function trade(
        GlobalDataLibrary.GlobalData storage globalData,
        IPredyPool.TradeParams memory tradeParams,
        bytes memory settlementData
    ) external returns (IPredyPool.TradeResult memory tradeResult) {
        DataType.PairStatus storage pairStatus = globalData.pairs[tradeParams.pairId];
        Perp.UserStatus storage openPosition = globalData.vaults[tradeParams.vaultId].openPosition;

        // settle user balance and fee
        DataType.FeeAmount memory realizedFee =
            settleUserBalanceAndFee(pairStatus, globalData.rebalanceFeeGrowthCache, openPosition);

        // calculate required token amounts
        (int256 underlyingAmountForSqrt, int256 stableAmountForSqrt) = Perp.computeRequiredAmounts(
            pairStatus.sqrtAssetStatus, pairStatus.isQuoteZero, openPosition, tradeParams.tradeAmountSqrt
        );

        tradeResult.sqrtPrice = getSqrtPrice(pairStatus.sqrtAssetStatus.uniswapPool, pairStatus.isQuoteZero);

        // swap tokens

        SwapStableResult memory swapResult = swap(
            globalData,
            tradeParams.pairId,
            SwapStableResult(-tradeParams.tradeAmount, underlyingAmountForSqrt, realizedFee.feeAmountBase, 0),
            settlementData,
            tradeResult.sqrtPrice,
            tradeParams.vaultId
        );

        tradeResult.averagePrice = swapResult.averagePrice;

        // add asset or debt
        tradeResult.payoff = Perp.updatePosition(
            pairStatus,
            openPosition,
            Perp.UpdatePerpParams(tradeParams.tradeAmount, swapResult.amountPerp),
            Perp.UpdateSqrtPerpParams(tradeParams.tradeAmountSqrt, swapResult.amountSqrtPerp + stableAmountForSqrt)
        );

        tradeResult.fee = realizedFee.feeAmountQuote + swapResult.fee;
        tradeResult.vaultId = tradeParams.vaultId;
    }

    function swap(
        GlobalDataLibrary.GlobalData storage globalData,
        uint256 pairId,
        SwapStableResult memory swapParams,
        bytes memory settlementData,
        uint256 sqrtPrice,
        uint256 vaultId
    ) internal returns (SwapStableResult memory) {
        int256 totalBaseAmount = swapParams.amountPerp + swapParams.amountSqrtPerp + swapParams.fee;

        if (totalBaseAmount == 0) {
            int256 amountQuote = calculateStableAmount(sqrtPrice, 1e18).toInt256();

            return divToStable(swapParams, int256(1e18), amountQuote, 0);
        }

        globalData.initializeLock(pairId);

        globalData.callSettlementCallback(settlementData, totalBaseAmount);

        (int256 settledQuoteAmount, int256 settledBaseAmount) = globalData.finalizeLock();

        if (settledBaseAmount != -totalBaseAmount) {
            revert IPredyPool.BaseTokenNotSettled();
        }

        // settledQuoteAmount must be non-zero
        if (settledQuoteAmount * totalBaseAmount <= 0) {
            revert IPredyPool.QuoteTokenNotSettled();
        }

        emit Swapped(pairId, vaultId, msg.sender, settledQuoteAmount, settledBaseAmount);

        return divToStable(swapParams, totalBaseAmount, settledQuoteAmount, settledQuoteAmount);
    }

    function getSqrtPrice(address uniswapPoolAddress, bool isQuoteZero) internal view returns (uint256 sqrtPriceX96) {
        return UniHelper.convertSqrtPrice(UniHelper.getSqrtPrice(uniswapPoolAddress), isQuoteZero);
    }

    function calculateStableAmount(uint256 currentSqrtPrice, uint256 baseAmount) internal pure returns (uint256) {
        uint256 quoteAmount = (currentSqrtPrice * baseAmount) >> Constants.RESOLUTION;

        return (quoteAmount * currentSqrtPrice) >> Constants.RESOLUTION;
    }

    function divToStable(
        SwapStableResult memory swapParams,
        int256 amountBase,
        int256 amountQuote,
        int256 totalAmountStable
    ) internal pure returns (SwapStableResult memory swapResult) {
        swapResult.amountPerp = amountQuote * swapParams.amountPerp / amountBase;
        swapResult.amountSqrtPerp = amountQuote * swapParams.amountSqrtPerp / amountBase;
        swapResult.fee = totalAmountStable - swapResult.amountPerp - swapResult.amountSqrtPerp;

        swapResult.averagePrice = amountQuote * int256(Constants.Q96) / Math.abs(amountBase).toInt256();
    }

    function settleUserBalanceAndFee(
        DataType.PairStatus storage _pairStatus,
        mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,
        Perp.UserStatus storage _userStatus
    ) internal returns (DataType.FeeAmount memory realizedFee) {
        realizedFee = PerpFee.settleUserFee(_pairStatus, rebalanceFeeGrowthCache, _userStatus);

        Perp.settleUserBalance(_pairStatus, _userStatus);
    }
}
