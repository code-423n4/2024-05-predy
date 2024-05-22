// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {ISettlement} from "./ISettlement.sol";
import {DataType} from "../libraries/DataType.sol";

interface IPredyPool {
    /// @notice Thrown when the caller is not operator
    error CallerIsNotOperator();

    /// @notice Thrown when the caller is not pool creator
    error CallerIsNotPoolCreator();

    /// @notice Thrown when the caller is not the current locker
    error LockedBy(address locker);

    /// @notice Thrown when a base token is not netted out after a lock
    error BaseTokenNotSettled();

    /// @notice Thrown when a quote token is not netted out after a lock
    error QuoteTokenNotSettled();

    /// @notice Thrown when a amount is 0
    error InvalidAmount();

    /// @notice Thrown when a pair id does not exist
    error InvalidPairId();

    /// @notice Thrown when a vault isn't danger
    error VaultIsNotDanger(int256 vaultValue, int256 minMargin);

    /// @notice Thrown when a trader address is not allowed
    error TraderNotAllowed();

    // VaultLib
    error VaultAlreadyHasAnotherPair();

    error VaultAlreadyHasAnotherMarginId();

    error CallerIsNotVaultOwner();

    struct TradeParams {
        uint256 pairId;
        uint256 vaultId;
        int256 tradeAmount;
        int256 tradeAmountSqrt;
        bytes extraData;
    }

    struct TradeResult {
        Payoff payoff;
        uint256 vaultId;
        int256 fee;
        int256 minMargin;
        int256 averagePrice;
        uint256 sqrtTwap;
        uint256 sqrtPrice;
    }

    struct Payoff {
        int256 perpEntryUpdate;
        int256 sqrtEntryUpdate;
        int256 sqrtRebalanceEntryUpdateUnderlying;
        int256 sqrtRebalanceEntryUpdateStable;
        int256 perpPayoff;
        int256 sqrtPayoff;
    }

    struct Position {
        int256 margin;
        int256 amountQuote;
        int256 amountSqrt;
        int256 amountBase;
    }

    struct VaultStatus {
        uint256 id;
        int256 vaultValue;
        int256 minMargin;
        uint256 oraclePrice;
        DataType.FeeAmount feeAmount;
        Position position;
    }

    function trade(TradeParams memory tradeParams, bytes memory settlementData)
        external
        returns (TradeResult memory tradeResult);
    function execLiquidationCall(uint256 vaultId, uint256 closeRatio, bytes memory settlementData)
        external
        returns (TradeResult memory tradeResult);

    function reallocate(uint256 pairId, bytes memory settlementData) external returns (bool relocationOccurred);

    function updateRecepient(uint256 vaultId, address recipient) external;

    function createVault(uint256 pairId) external returns (uint256);

    function take(bool isQuoteAsset, address to, uint256 amount) external;

    function getSqrtPrice(uint256 pairId) external view returns (uint160);

    function getSqrtIndexPrice(uint256 pairId) external view returns (uint256);

    function getVault(uint256 vaultId) external view returns (DataType.Vault memory);
    function getPairStatus(uint256 pairId) external view returns (DataType.PairStatus memory);

    function revertPairStatus(uint256 pairId) external;
    function revertVaultStatus(uint256 vaultId) external;
}
