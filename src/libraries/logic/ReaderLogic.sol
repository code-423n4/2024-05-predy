// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {Constants} from "../Constants.sol";
import {DataType} from "../DataType.sol";
import {Perp} from "../Perp.sol";
import {PerpFee} from "../PerpFee.sol";
import {ApplyInterestLib} from "../ApplyInterestLib.sol";
import {GlobalDataLibrary} from "../../types/GlobalData.sol";
import {PositionCalculator} from "../PositionCalculator.sol";

library ReaderLogic {
    using GlobalDataLibrary for GlobalDataLibrary.GlobalData;

    function getPairStatus(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) external {
        ApplyInterestLib.applyInterestForToken(globalData.pairs, pairId);

        DataType.PairStatus memory pairStatus = globalData.pairs[pairId];

        revertPairStatus(pairStatus);
    }

    function getVaultStatus(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId) external {
        DataType.Vault memory vault = globalData.vaults[vaultId];
        DataType.PairStatus storage pairStatus = globalData.pairs[vault.openPosition.pairId];

        ApplyInterestLib.applyInterestForToken(globalData.pairs, vault.openPosition.pairId);

        Perp.updateRebalanceInterestGrowth(pairStatus, pairStatus.sqrtAssetStatus);

        DataType.FeeAmount memory feeAmount =
            PerpFee.computeUserFee(pairStatus, globalData.rebalanceFeeGrowthCache, vault.openPosition);

        (int256 minMargin, int256 vaultValue,, uint256 oraclePice) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, feeAmount);

        revertVaultStatus(
            IPredyPool.VaultStatus(vaultId, vaultValue, minMargin, oraclePice, feeAmount, getPosition(vault, feeAmount))
        );
    }

    function getPosition(DataType.Vault memory vault, DataType.FeeAmount memory feeAmount)
        internal
        pure
        returns (IPredyPool.Position memory)
    {
        PositionCalculator.PositionParams memory positionParams =
            PositionCalculator.getPositionWithFeeAmount(vault.openPosition, feeAmount);

        return IPredyPool.Position(
            vault.margin, positionParams.amountQuote, positionParams.amountSqrt, positionParams.amountBase
        );
    }

    function revertPairStatus(DataType.PairStatus memory pairStatus) internal pure {
        bytes memory data = abi.encode(pairStatus);

        assembly {
            revert(add(32, data), mload(data))
        }
    }

    function revertVaultStatus(IPredyPool.VaultStatus memory vaultStatus) internal pure {
        bytes memory data = abi.encode(vaultStatus);

        assembly {
            revert(add(32, data), mload(data))
        }
    }
}
