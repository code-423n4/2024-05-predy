// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IPredyPool} from "./interfaces/IPredyPool.sol";
import {IHooks} from "./interfaces/IHooks.sol";
import {ISettlement} from "./interfaces/ISettlement.sol";
import {Perp} from "./libraries/Perp.sol";
import {VaultLib} from "./libraries/VaultLib.sol";
import {PositionCalculator} from "./libraries/PositionCalculator.sol";
import {DataType} from "./libraries/DataType.sol";
import {InterestRateModel} from "./libraries/InterestRateModel.sol";
import {UniHelper} from "./libraries/UniHelper.sol";
import {AddPairLogic} from "./libraries/logic/AddPairLogic.sol";
import {LiquidationLogic} from "./libraries/logic/LiquidationLogic.sol";
import {ReallocationLogic} from "./libraries/logic/ReallocationLogic.sol";
import {SupplyLogic} from "./libraries/logic/SupplyLogic.sol";
import {TradeLogic} from "./libraries/logic/TradeLogic.sol";
import {ReaderLogic} from "./libraries/logic/ReaderLogic.sol";
import {LockDataLibrary, GlobalDataLibrary} from "./types/GlobalData.sol";

/// @notice Holds the state for all pairs and vaults
contract PredyPool is IPredyPool, IUniswapV3MintCallback, Initializable, ReentrancyGuardUpgradeable {
    using GlobalDataLibrary for GlobalDataLibrary.GlobalData;
    using LockDataLibrary for LockDataLibrary.LockData;
    using VaultLib for GlobalDataLibrary.GlobalData;
    using SafeTransferLib for ERC20;

    address public operator;

    GlobalDataLibrary.GlobalData public globalData;

    mapping(address => bool) public allowedUniswapPools;

    mapping(address trader => mapping(uint256 pairId => bool)) public allowedTraders;

    event OperatorUpdated(address operator);
    event RecepientUpdated(uint256 vaultId, address recipient);
    event ProtocolRevenueWithdrawn(uint256 pairId, bool isStable, uint256 amount);
    event CreatorRevenueWithdrawn(uint256 pairId, bool isStable, uint256 amount);

    modifier onlyOperator() {
        if (operator != msg.sender) revert CallerIsNotOperator();
        _;
    }

    modifier onlyByLocker() {
        address locker = globalData.lockData.locker;
        if (msg.sender != locker) revert LockedBy(locker);
        _;
    }

    modifier onlyPoolOwner(uint256 pairId) {
        if (globalData.pairs[pairId].poolOwner != msg.sender) revert CallerIsNotPoolCreator();
        _;
    }

    modifier onlyVaultOwner(uint256 vaultId) {
        if (globalData.vaults[vaultId].owner != msg.sender) revert CallerIsNotVaultOwner();
        _;
    }

    constructor() {}

    function initialize(address uniswapFactory) public initializer {
        __ReentrancyGuard_init();
        AddPairLogic.initializeGlobalData(globalData, uniswapFactory);

        operator = msg.sender;
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata) external override {
        // Only the uniswap pool has access to this function.
        require(allowedUniswapPools[msg.sender]);

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(msg.sender);

        if (amount0 > 0) {
            ERC20(uniswapPool.token0()).safeTransfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            ERC20(uniswapPool.token1()).safeTransfer(msg.sender, amount1);
        }
    }

    /**
     * @notice Sets new operator
     * @dev Only operator can call this function.
     * @param newOperator The address of new operator
     */
    function setOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0));
        operator = newOperator;

        emit OperatorUpdated(newOperator);
    }

    /**
     * @notice Adds a new trading pair.
     * @param addPairParam AddPairParams struct containing pair information.
     * @return pairId The id of the pair.
     */
    function registerPair(AddPairLogic.AddPairParams memory addPairParam) external onlyOperator returns (uint256) {
        return AddPairLogic.addPair(globalData, allowedUniswapPools, addPairParam);
    }

    /**
     * @notice Updates asset risk parameters.
     * @dev The function can be called by pool owner.
     * @param pairId The id of asset to update params.
     * @param riskParams Asset risk parameters.
     */
    function updateAssetRiskParams(uint256 pairId, Perp.AssetRiskParams memory riskParams)
        external
        onlyPoolOwner(pairId)
    {
        AddPairLogic.updateAssetRiskParams(globalData.pairs[pairId], riskParams);
    }

    /**
     * @notice Updates interest rate model parameters.
     * @dev The function can be called by pool owner.
     * @param pairId The id of pair to update params.
     * @param quoteIrmParams Asset interest-rate parameters for quote token.
     * @param baseIrmParams Asset interest-rate parameters for base token.
     */
    function updateIRMParams(
        uint256 pairId,
        InterestRateModel.IRMParams memory quoteIrmParams,
        InterestRateModel.IRMParams memory baseIrmParams
    ) external onlyPoolOwner(pairId) {
        AddPairLogic.updateIRMParams(globalData.pairs[pairId], quoteIrmParams, baseIrmParams);
    }

    /**
     * @notice Updates fee ratio
     * @dev The function can be called by pool owner.
     * @param pairId The id of pair to update params.
     * @param feeRatio The ratio of fee
     */
    function updateFeeRatio(uint256 pairId, uint8 feeRatio) external onlyPoolOwner(pairId) {
        AddPairLogic.updateFeeRatio(globalData.pairs[pairId], feeRatio);
    }

    /**
     * @notice Updates pool owner
     * @dev The function can be called by pool owner.
     * @param pairId The id of pair to update owner.
     * @param poolOwner The address of pool owner
     */
    function updatePoolOwner(uint256 pairId, address poolOwner) external onlyPoolOwner(pairId) {
        AddPairLogic.updatePoolOwner(globalData.pairs[pairId], poolOwner);
    }

    /**
     * @notice Updates price oracle
     * @dev The function can be called by pool owner.
     * @param pairId The id of pair to update oracle.
     * @param priceFeed The address of price feed
     */
    function updatePriceOracle(uint256 pairId, address priceFeed) external onlyPoolOwner(pairId) {
        AddPairLogic.updatePriceOracle(globalData.pairs[pairId], priceFeed);
    }

    /**
     * @notice Withdraws accumulated protocol revenue.
     * @dev Only operator can call this function.
     * @param pairId The id of pair
     * @param isQuoteToken Is quote or base
     */
    function withdrawProtocolRevenue(uint256 pairId, bool isQuoteToken) external onlyOperator {
        Perp.AssetPoolStatus storage pool = _getAssetStatusPool(pairId, isQuoteToken);

        uint256 amount = pool.accumulatedProtocolRevenue;

        require(amount > 0, "AZ");

        pool.accumulatedProtocolRevenue = 0;

        if (amount > 0) {
            ERC20(pool.token).safeTransfer(msg.sender, amount);
        }

        emit ProtocolRevenueWithdrawn(pairId, isQuoteToken, amount);
    }

    /**
     * @notice Withdraws accumulated creator revenue.
     * @dev Only pool owner can call this function.
     * @param pairId The id of pair
     * @param isQuoteToken Is quote or base
     */
    function withdrawCreatorRevenue(uint256 pairId, bool isQuoteToken) external onlyPoolOwner(pairId) {
        Perp.AssetPoolStatus storage pool = _getAssetStatusPool(pairId, isQuoteToken);

        uint256 amount = pool.accumulatedCreatorRevenue;

        require(amount > 0, "AZ");

        pool.accumulatedCreatorRevenue = 0;

        if (amount > 0) {
            ERC20(pool.token).safeTransfer(msg.sender, amount);
        }

        emit CreatorRevenueWithdrawn(pairId, isQuoteToken, amount);
    }

    /**
     * @notice Supplies either the quoteToken or the baseToken to the lending pool.
     * In return, the lender receives bond tokens.
     * @param pairId The id of pair to supply liquidity
     * @param isQuoteAsset Whether the token is quote or base
     * @param supplyAmount The amount of tokens to supply
     */
    function supply(uint256 pairId, bool isQuoteAsset, uint256 supplyAmount)
        external
        nonReentrant
        returns (uint256 finalSuppliedAmount)
    {
        return SupplyLogic.supply(globalData, pairId, supplyAmount, isQuoteAsset);
    }

    /**
     * @notice Withdraws either the quoteToken or the baseToken from the lending pool.
     * In return, the lender burns the bond tokens.
     * @param pairId The id of pair to withdraw liquidity
     * @param isQuoteAsset Whether the token is quote or base
     * @param withdrawAmount The amount of tokens to withdraw
     */
    function withdraw(uint256 pairId, bool isQuoteAsset, uint256 withdrawAmount)
        external
        nonReentrant
        returns (uint256 finalBurnAmount, uint256 finalWithdrawAmount)
    {
        return SupplyLogic.withdraw(globalData, pairId, withdrawAmount, isQuoteAsset);
    }

    /**
     * @notice Reallocates the range of concentrated liquidity provider position to be in-range.
     * @param pairId The id of pair to reallocate the range.
     * @param settlementData byte data for settlement contract.
     * @return relocationOccurred Whether relocation occurred.
     */
    function reallocate(uint256 pairId, bytes memory settlementData)
        external
        nonReentrant
        returns (bool relocationOccurred)
    {
        return ReallocationLogic.reallocate(globalData, pairId, settlementData);
    }

    /**
     * @notice Trades perps and squarts. If vaultId is 0, it creates a new vault.
     * @param tradeParams trade details
     * @param settlementData byte data for settlement contract.
     * @return tradeResult The result of the trade.
     */
    function trade(TradeParams memory tradeParams, bytes memory settlementData)
        external
        nonReentrant
        returns (TradeResult memory tradeResult)
    {
        globalData.validate(tradeParams.pairId);

        if (globalData.pairs[tradeParams.pairId].allowlistEnabled && !allowedTraders[msg.sender][tradeParams.pairId]) {
            revert TraderNotAllowed();
        }

        tradeParams.vaultId = globalData.createOrGetVault(tradeParams.vaultId, tradeParams.pairId);

        return TradeLogic.trade(globalData, tradeParams, settlementData);
    }

    /**
     * @notice Updates the recipient. If the position is liquidated, the remaining margin is sent to the recipient.
     * @param vaultId The id of the vault.
     * @param recipient if recipient is zero address, protocol never transfers margin.
     */
    function updateRecepient(uint256 vaultId, address recipient) external onlyVaultOwner(vaultId) {
        DataType.Vault storage vault = globalData.vaults[vaultId];

        vault.recipient = recipient;

        emit RecepientUpdated(vaultId, recipient);
    }

    /**
     * @notice Sets the authorized traders. When allowlistEnabled is true, only authorized traders are allowed to trade.
     * @param pairId The id of pair
     * @param trader The address of allowed trader
     * @param enabled Whether the trader is allowed to trade
     */
    function allowTrader(uint256 pairId, address trader, bool enabled) external onlyPoolOwner(pairId) {
        require(globalData.pairs[pairId].allowlistEnabled);

        allowedTraders[trader][pairId] = enabled;
    }

    /**
     * @notice Executes a liquidation call to close an unsafe vault.
     * @param vaultId The identifier of the vault to be liquidated.
     * @param closeRatio The ratio at which the position will be closed.
     * @param settlementData SettlementData struct for trade settlement.
     * @return tradeResult TradeResult struct with the result of the liquidation.
     */
    function execLiquidationCall(uint256 vaultId, uint256 closeRatio, bytes memory settlementData)
        external
        nonReentrant
        returns (TradeResult memory tradeResult)
    {
        return LiquidationLogic.liquidate(vaultId, closeRatio, globalData, settlementData);
    }

    /**
     * @notice Transfers tokens. It can only be called from within the `predySettlementCallback` and
     * `predyTradeAfterCallback` of the contract that invoked the trade function.
     * @dev Only the current locker can call this function
     * @param isQuoteAsset Whether the token is quote or base
     * @param to The address to transfer the tokens to
     * @param amount The amount of tokens to transfer
     */
    function take(bool isQuoteAsset, address to, uint256 amount) external onlyByLocker {
        globalData.take(isQuoteAsset, to, amount);
    }

    /**
     * @notice Creates a new vault
     * @param pairId The id of pair to create vault
     */
    function createVault(uint256 pairId) external returns (uint256) {
        globalData.validate(pairId);

        return globalData.createOrGetVault(0, pairId);
    }

    /// @notice Gets the square root of the AMM price
    function getSqrtPrice(uint256 pairId) external view returns (uint160) {
        return UniHelper.convertSqrtPrice(
            UniHelper.getSqrtPrice(globalData.pairs[pairId].sqrtAssetStatus.uniswapPool),
            globalData.pairs[pairId].isQuoteZero
        );
    }

    /// @notice Gets the square root of the index price
    function getSqrtIndexPrice(uint256 pairId) external view returns (uint256) {
        return PositionCalculator.getSqrtIndexPrice(globalData.pairs[pairId]);
    }

    /// @notice Gets the status of pair
    function getPairStatus(uint256 pairId) external view returns (DataType.PairStatus memory) {
        globalData.validate(pairId);

        return globalData.pairs[pairId];
    }

    /// @notice Gets the vault
    function getVault(uint256 vaultId) external view returns (DataType.Vault memory) {
        return globalData.vaults[vaultId];
    }

    /// @notice Gets the status of pair
    /// @dev This function always reverts
    function revertPairStatus(uint256 pairId) external {
        ReaderLogic.getPairStatus(globalData, pairId);
    }

    /// @notice Gets the status of the vault
    /// @dev This function always reverts
    function revertVaultStatus(uint256 vaultId) external {
        ReaderLogic.getVaultStatus(globalData, vaultId);
    }

    function _getAssetStatusPool(uint256 pairId, bool isQuoteToken)
        internal
        view
        returns (Perp.AssetPoolStatus storage)
    {
        if (isQuoteToken) {
            return globalData.pairs[pairId].quotePool;
        } else {
            return globalData.pairs[pairId].basePool;
        }
    }
}
