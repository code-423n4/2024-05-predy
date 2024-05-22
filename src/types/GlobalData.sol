// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import "../interfaces/IPredyPool.sol";
import {IHooks} from "../interfaces/IHooks.sol";
import "../libraries/DataType.sol";
import "./LockData.sol";

library GlobalDataLibrary {
    using SafeTransferLib for ERC20;
    using SafeCast for uint256;

    struct GlobalData {
        uint256 pairsCount;
        uint256 vaultCount;
        address uniswapFactory;
        mapping(uint256 => DataType.PairStatus) pairs;
        mapping(uint256 => DataType.RebalanceFeeGrowthCache) rebalanceFeeGrowthCache;
        mapping(uint256 => DataType.Vault) vaults;
        LockDataLibrary.LockData lockData;
    }

    function validateVaultId(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId) internal view {
        if (vaultId <= 0 || globalData.vaultCount <= vaultId) revert IPredyPool.InvalidPairId();
    }

    function validate(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) internal view {
        if (pairId <= 0 || globalData.pairsCount <= pairId) revert IPredyPool.InvalidPairId();
    }

    /// @notice Initializes lock for token settlement
    function initializeLock(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) internal {
        if (globalData.lockData.locker != address(0)) {
            revert IPredyPool.LockedBy(globalData.lockData.locker);
        }

        globalData.lockData.quoteReserve = ERC20(globalData.pairs[pairId].quotePool.token).balanceOf(address(this));
        globalData.lockData.baseReserve = ERC20(globalData.pairs[pairId].basePool.token).balanceOf(address(this));
        globalData.lockData.locker = msg.sender;
        globalData.lockData.pairId = pairId;
    }

    function callSettlementCallback(
        GlobalDataLibrary.GlobalData storage globalData,
        bytes memory settlementData,
        int256 deltaBaseAmount
    ) internal {
        uint256 pairId = globalData.lockData.pairId;

        IHooks(msg.sender).predySettlementCallback(
            globalData.pairs[pairId].quotePool.token,
            globalData.pairs[pairId].basePool.token,
            settlementData,
            deltaBaseAmount
        );
    }

    /// @notice Finalizes lock
    function finalizeLock(GlobalDataLibrary.GlobalData storage globalData)
        internal
        returns (int256 paidQuote, int256 paidBase)
    {
        paidQuote = settle(globalData, true);
        paidBase = settle(globalData, false);

        delete globalData.lockData;
    }

    function take(GlobalDataLibrary.GlobalData storage globalData, bool isQuoteAsset, address to, uint256 amount)
        internal
    {
        DataType.PairStatus memory pairStatus = globalData.pairs[globalData.lockData.pairId];

        address currency;

        if (isQuoteAsset) {
            currency = pairStatus.quotePool.token;
        } else {
            currency = pairStatus.basePool.token;
        }

        ERC20(currency).safeTransfer(to, amount);
    }

    function settle(GlobalDataLibrary.GlobalData storage globalData, bool isQuoteAsset)
        internal
        returns (int256 paid)
    {
        address currency;
        uint256 reservesBefore;

        if (isQuoteAsset) {
            currency = globalData.pairs[globalData.lockData.pairId].quotePool.token;
            reservesBefore = globalData.lockData.quoteReserve;
        } else {
            currency = globalData.pairs[globalData.lockData.pairId].basePool.token;
            reservesBefore = globalData.lockData.baseReserve;
        }

        uint256 reserveAfter = ERC20(currency).balanceOf(address(this));

        if (isQuoteAsset) {
            globalData.lockData.quoteReserve = reserveAfter;
        } else {
            globalData.lockData.baseReserve = reserveAfter;
        }

        paid = reserveAfter.toInt256() - reservesBefore.toInt256();
    }
}
