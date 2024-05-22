// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ISettlement} from "../../interfaces/ISettlement.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {DataType} from "../DataType.sol";
import {Perp} from "../Perp.sol";
import {PairLib} from "../PairLib.sol";
import {ApplyInterestLib} from "../ApplyInterestLib.sol";
import {GlobalDataLibrary} from "../../types/GlobalData.sol";

library ReallocationLogic {
    using GlobalDataLibrary for GlobalDataLibrary.GlobalData;
    using SafeTransferLib for ERC20;

    event Rebalanced(
        uint256 indexed pairId,
        bool relocationOccurred,
        int24 tickLower,
        int24 tickUpper,
        int256 deltaPositionBase,
        int256 deltaPositionQuote
    );

    function reallocate(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId, bytes memory settlementData)
        external
        returns (bool isRangeChanged)
    {
        // Checks the pair exists
        globalData.validate(pairId);

        // Updates interest rate related to the pair
        ApplyInterestLib.applyInterestForToken(globalData.pairs, pairId);

        DataType.PairStatus storage pairStatus = globalData.pairs[pairId];

        // Clear rebalance interests up to this block and update interest growth variables
        Perp.updateRebalanceInterestGrowth(pairStatus, pairStatus.sqrtAssetStatus);

        bool relocationOccurred;

        {
            int256 deltaPositionBase;
            int256 deltaPositionQuote;

            (relocationOccurred, isRangeChanged, deltaPositionBase, deltaPositionQuote) =
                Perp.reallocate(pairStatus, pairStatus.sqrtAssetStatus);

            if (deltaPositionBase != 0) {
                globalData.initializeLock(pairId);

                globalData.callSettlementCallback(settlementData, deltaPositionBase);

                (int256 settledQuoteAmount, int256 settledBaseAmount) = globalData.finalizeLock();

                int256 exceedsQuote = settledQuoteAmount + deltaPositionQuote;

                if (exceedsQuote < 0) {
                    revert IPredyPool.QuoteTokenNotSettled();
                }

                if (settledBaseAmount + deltaPositionBase != 0) {
                    revert IPredyPool.BaseTokenNotSettled();
                }

                if (exceedsQuote > 0) {
                    ERC20(pairStatus.quotePool.token).safeTransfer(msg.sender, uint256(exceedsQuote));
                }
            }

            emit Rebalanced(
                pairId,
                relocationOccurred,
                pairStatus.sqrtAssetStatus.tickLower,
                pairStatus.sqrtAssetStatus.tickUpper,
                deltaPositionBase,
                deltaPositionQuote
            );
        }

        if (relocationOccurred) {
            globalData.rebalanceFeeGrowthCache[PairLib.getRebalanceCacheId(
                pairId, pairStatus.sqrtAssetStatus.numRebalance
            )] = DataType.RebalanceFeeGrowthCache(
                pairStatus.sqrtAssetStatus.rebalanceInterestGrowthQuote,
                pairStatus.sqrtAssetStatus.rebalanceInterestGrowthBase
            );

            Perp.finalizeReallocation(pairStatus.sqrtAssetStatus);
        }
    }
}
