// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {DataType} from "./DataType.sol";
import {GlobalDataLibrary} from "../types/GlobalData.sol";

library VaultLib {
    event VaultCreated(uint256 vaultId, address owner, address quoteToken, uint256 pairId);

    function getVault(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId)
        internal
        view
        returns (DataType.Vault storage vault)
    {
        vault = globalData.vaults[vaultId];

        // Ensure the caller is the owner of the existing vault
        if (vault.owner != msg.sender) {
            revert IPredyPool.CallerIsNotVaultOwner();
        }
    }

    function createOrGetVault(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId, uint256 pairId)
        internal
        returns (uint256)
    {
        address quoteToken = globalData.pairs[pairId].quoteToken;

        if (vaultId == 0) {
            uint256 finalVaultId = globalData.vaultCount;

            // Initialize a new vault
            DataType.Vault storage vault = globalData.vaults[finalVaultId];

            vault.id = finalVaultId;
            vault.owner = msg.sender;
            vault.recipient = msg.sender;
            vault.openPosition.pairId = pairId;
            vault.quoteToken = quoteToken;

            globalData.vaultCount++;

            emit VaultCreated(vault.id, vault.owner, quoteToken, pairId);

            return vault.id;
        } else {
            DataType.Vault memory vault = globalData.vaults[vaultId];

            // Ensure the caller is the owner of the existing vault
            if (vault.owner != msg.sender) {
                revert IPredyPool.CallerIsNotVaultOwner();
            }

            if (vault.quoteToken != quoteToken) {
                revert IPredyPool.VaultAlreadyHasAnotherMarginId();
            }

            if (vault.openPosition.pairId != pairId) {
                revert IPredyPool.VaultAlreadyHasAnotherPair();
            }

            return vault.id;
        }
    }
}
