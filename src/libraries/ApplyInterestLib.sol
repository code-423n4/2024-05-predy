// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "./Perp.sol";
import "./ScaledAsset.sol";
import "./DataType.sol";

library ApplyInterestLib {
    using ScaledAsset for ScaledAsset.AssetStatus;

    /// @notice Emitted when interest growth is updated
    event InterestGrowthUpdated(
        uint256 indexed pairId,
        ScaledAsset.AssetStatus quoteStatus,
        ScaledAsset.AssetStatus baseStatus,
        uint256 interestRateQuote,
        uint256 interestRateBase,
        uint256 protocolFeeQuote,
        uint256 protocolFeeBase
    );

    /**
     * @notice Each time a user interacts with the contract, interest and premium from the previous interaction to the current one are applied.
     * This increases the amount available for withdrawal by the lender and the premium income for Squart.
     */
    function applyInterestForToken(mapping(uint256 => DataType.PairStatus) storage pairs, uint256 pairId) internal {
        DataType.PairStatus storage pairStatus = pairs[pairId];

        Perp.updateFeeAndPremiumGrowth(pairId, pairStatus.sqrtAssetStatus);

        // avoid applying interest rate multiple times in the same block
        if (pairStatus.lastUpdateTimestamp >= block.timestamp) {
            return;
        }

        (uint256 interestRateQuote, uint256 protocolFeeQuote) =
            applyInterestForPoolStatus(pairStatus.quotePool, pairStatus.lastUpdateTimestamp, pairStatus.feeRatio);

        (uint256 interestRateBase, uint256 protocolFeeBase) =
            applyInterestForPoolStatus(pairStatus.basePool, pairStatus.lastUpdateTimestamp, pairStatus.feeRatio);

        // Update last update timestamp
        pairStatus.lastUpdateTimestamp = block.timestamp;

        if (interestRateQuote > 0 || interestRateBase > 0) {
            emitInterestGrowthEvent(pairStatus, interestRateQuote, interestRateBase, protocolFeeQuote, protocolFeeBase);
        }
    }

    function applyInterestForPoolStatus(Perp.AssetPoolStatus storage poolStatus, uint256 lastUpdateTimestamp, uint8 fee)
        internal
        returns (uint256 interestRate, uint256 totalProtocolFee)
    {
        if (block.timestamp <= lastUpdateTimestamp) {
            return (0, 0);
        }

        uint256 utilizationRatio = poolStatus.tokenStatus.getUtilizationRatio();

        // Skip calculating interest if utilization ratio is 0
        if (utilizationRatio == 0) {
            return (0, 0);
        }

        // Calculates interest rate
        interestRate = InterestRateModel.calculateInterestRate(poolStatus.irmParams, utilizationRatio)
            * (block.timestamp - lastUpdateTimestamp) / 365 days;

        totalProtocolFee = poolStatus.tokenStatus.updateScaler(interestRate, fee);

        poolStatus.accumulatedProtocolRevenue += totalProtocolFee / 2;
        poolStatus.accumulatedCreatorRevenue += totalProtocolFee / 2;
    }

    function emitInterestGrowthEvent(
        DataType.PairStatus memory assetStatus,
        uint256 interestRateQuote,
        uint256 interestRateBase,
        uint256 totalProtocolFeeQuote,
        uint256 totalProtocolFeeBase
    ) internal {
        emit InterestGrowthUpdated(
            assetStatus.id,
            assetStatus.quotePool.tokenStatus,
            assetStatus.basePool.tokenStatus,
            interestRateQuote,
            interestRateBase,
            totalProtocolFeeQuote,
            totalProtocolFeeBase
        );
    }
}
