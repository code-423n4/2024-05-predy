// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {BaseMarketUpgradable} from "../../base/BaseMarketUpgradable.sol";
import {BaseHookCallbackUpgradable} from "../../base/BaseHookCallbackUpgradable.sol";
import {Permit2Lib} from "../../libraries/orders/Permit2Lib.sol";
import {ResolvedOrder, ResolvedOrderLib} from "../../libraries/orders/ResolvedOrder.sol";
import {SlippageLib} from "../../libraries/SlippageLib.sol";
import {Bps} from "../../libraries/math/Bps.sol";
import {DataType} from "../../libraries/DataType.sol";
import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";
import {ArrayLib} from "./ArrayLib.sol";
import {GammaTradeMarketLib} from "./GammaTradeMarketLib.sol";

/**
 * @notice Gamma trade market contract
 */
contract GammaTradeMarket is IFillerMarket, BaseMarketUpgradable, ReentrancyGuardUpgradeable {
    using ResolvedOrderLib for ResolvedOrder;
    using ArrayLib for uint256[];
    using GammaOrderLib for GammaOrder;
    using Permit2Lib for ResolvedOrder;
    using SafeTransferLib for ERC20;

    error PositionNotFound();
    error PositionHasDifferentPairId();
    error PositionIsNotClosed();
    error InvalidOrder();
    error SignerIsNotPositionOwner();
    error HedgeTriggerNotMatched();
    error DeltaIsZero();
    error AlreadyClosed();
    error AutoCloseTriggerNotMatched();
    error MarginUpdateMustBeZero();

    struct CallbackData {
        GammaTradeMarketLib.CallbackType callbackType;
        address trader;
        int256 marginAmountUpdate;
    }

    IPermit2 internal _permit2;

    mapping(address owner => uint256[]) internal positionIDs;
    mapping(uint256 positionId => GammaTradeMarketLib.UserPosition) internal userPositions;

    event GammaPositionTraded(
        address indexed trader,
        uint256 pairId,
        uint256 positionId,
        int256 quantity,
        int256 quantitySqrt,
        IPredyPool.Payoff payoff,
        int256 fee,
        int256 marginAmount,
        GammaTradeMarketLib.CallbackType callbackType
    );

    event GammaPositionModified(address indexed trader, uint256 pairId, uint256 positionId, GammaModifyInfo modifyInfo);

    constructor() {}

    function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

        _permit2 = IPermit2(permit2Address);
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external override(BaseHookCallbackUpgradable) onlyPredyPool {
        CallbackData memory callbackData = abi.decode(tradeParams.extraData, (CallbackData));
        ERC20 quoteToken = ERC20(_getQuoteTokenAddress(tradeParams.pairId));

        if (callbackData.callbackType == GammaTradeMarketLib.CallbackType.QUOTE) {
            _revertTradeResult(tradeResult);
        } else {
            if (tradeResult.minMargin == 0) {
                if (callbackData.marginAmountUpdate != 0) {
                    revert MarginUpdateMustBeZero();
                }

                DataType.Vault memory vault = _predyPool.getVault(tradeParams.vaultId);

                _predyPool.take(true, callbackData.trader, uint256(vault.margin));

                // remove position index
                _removePosition(tradeParams.vaultId);

                emit GammaPositionTraded(
                    callbackData.trader,
                    tradeParams.pairId,
                    tradeParams.vaultId,
                    tradeParams.tradeAmount,
                    tradeParams.tradeAmountSqrt,
                    tradeResult.payoff,
                    tradeResult.fee,
                    -vault.margin,
                    callbackData.callbackType == GammaTradeMarketLib.CallbackType.TRADE
                        ? GammaTradeMarketLib.CallbackType.CLOSE
                        : callbackData.callbackType
                );
            } else {
                int256 marginAmountUpdate = callbackData.marginAmountUpdate;

                if (marginAmountUpdate > 0) {
                    quoteToken.safeTransfer(address(_predyPool), uint256(marginAmountUpdate));
                } else if (marginAmountUpdate < 0) {
                    _predyPool.take(true, callbackData.trader, uint256(-marginAmountUpdate));
                }

                emit GammaPositionTraded(
                    callbackData.trader,
                    tradeParams.pairId,
                    tradeParams.vaultId,
                    tradeParams.tradeAmount,
                    tradeParams.tradeAmountSqrt,
                    tradeResult.payoff,
                    tradeResult.fee,
                    marginAmountUpdate,
                    callbackData.callbackType
                );
            }
        }
    }

    function execLiquidationCall(
        uint256 vaultId,
        uint256 closeRatio,
        IFillerMarket.SettlementParamsV3 memory settlementParams
    ) external override returns (IPredyPool.TradeResult memory tradeResult) {
        tradeResult =
            _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementDataFromV3(settlementParams, msg.sender));

        if (closeRatio == 1e18) {
            _removePosition(vaultId);
        }
    }

    // open position
    function _executeTrade(GammaOrder memory gammaOrder, bytes memory sig, SettlementParamsV3 memory settlementParams)
        internal
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        ResolvedOrder memory resolvedOrder = GammaOrderLib.resolve(gammaOrder, sig);

        _validateQuoteTokenAddress(gammaOrder.pairId, gammaOrder.entryTokenAddress);

        _verifyOrder(resolvedOrder);

        // execute trade
        tradeResult = _predyPool.trade(
            IPredyPool.TradeParams(
                gammaOrder.pairId,
                gammaOrder.positionId,
                gammaOrder.quantity,
                gammaOrder.quantitySqrt,
                abi.encode(
                    CallbackData(
                        GammaTradeMarketLib.CallbackType.TRADE, gammaOrder.info.trader, gammaOrder.marginAmount
                    )
                )
            ),
            _getSettlementDataFromV3(settlementParams, msg.sender)
        );

        if (tradeResult.minMargin > 0) {
            // only whitelisted filler can open position
            if (msg.sender != whitelistFiller) {
                revert CallerIsNotFiller();
            }
        }

        GammaTradeMarketLib.UserPosition storage userPosition = _getOrInitPosition(
            tradeResult.vaultId, gammaOrder.positionId == 0, gammaOrder.info.trader, gammaOrder.pairId
        );

        _saveUserPosition(userPosition, gammaOrder.modifyInfo);

        userPosition.leverage = gammaOrder.leverage;

        // init last hedge status
        userPosition.lastHedgedSqrtPrice = tradeResult.sqrtTwap;
        userPosition.lastHedgedTime = block.timestamp;

        if (gammaOrder.positionId == 0) {
            _addPositionIndex(gammaOrder.info.trader, userPosition.vaultId);

            _predyPool.updateRecepient(tradeResult.vaultId, gammaOrder.info.trader);
        }

        SlippageLib.checkPrice(
            gammaOrder.baseSqrtPrice,
            tradeResult,
            gammaOrder.slippageTolerance,
            SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE
        );
    }

    function _modifyAutoHedgeAndClose(GammaOrder memory gammaOrder, bytes memory sig) internal {
        if (gammaOrder.quantity != 0 || gammaOrder.quantitySqrt != 0 || gammaOrder.marginAmount != 0) {
            revert InvalidOrder();
        }

        ResolvedOrder memory resolvedOrder = GammaOrderLib.resolve(gammaOrder, sig);

        _verifyOrder(resolvedOrder);

        // save user position
        GammaTradeMarketLib.UserPosition storage userPosition =
            _getOrInitPosition(gammaOrder.positionId, false, gammaOrder.info.trader, gammaOrder.pairId);

        _saveUserPosition(userPosition, gammaOrder.modifyInfo);
    }

    function autoHedge(uint256 positionId, SettlementParamsV3 memory settlementParams)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        GammaTradeMarketLib.UserPosition storage userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0 || positionId != userPosition.vaultId) {
            revert PositionNotFound();
        }

        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        // check auto hedge condition
        (bool hedgeRequired, uint256 slippageTorelance, GammaTradeMarketLib.CallbackType triggerType) =
            GammaTradeMarketLib.validateHedgeCondition(userPosition, sqrtPrice);

        if (!hedgeRequired) {
            revert HedgeTriggerNotMatched();
        }

        userPosition.lastHedgedSqrtPrice = sqrtPrice;
        userPosition.lastHedgedTime = block.timestamp;

        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        int256 delta = GammaTradeMarketLib.calculateDelta(
            sqrtPrice, userPosition.maximaDeviation, vault.openPosition.sqrtPerp.amount, vault.openPosition.perp.amount
        );

        if (delta == 0) {
            revert DeltaIsZero();
        }

        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(
            userPosition.pairId,
            userPosition.vaultId,
            -delta,
            0,
            abi.encode(CallbackData(triggerType, userPosition.owner, 0))
        );

        // execute trade
        tradeResult = _predyPool.trade(tradeParams, _getSettlementDataFromV3(settlementParams, msg.sender));

        SlippageLib.checkPrice(sqrtPrice, tradeResult, slippageTorelance, SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE);
    }

    function autoClose(uint256 positionId, SettlementParamsV3 memory settlementParams)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        // save user position
        GammaTradeMarketLib.UserPosition memory userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0 || positionId != userPosition.vaultId) {
            revert PositionNotFound();
        }

        // check auto close condition
        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        (bool closeRequired, uint256 slippageTorelance, GammaTradeMarketLib.CallbackType triggerType) =
            GammaTradeMarketLib.validateCloseCondition(userPosition, sqrtPrice);

        if (!closeRequired) {
            revert AutoCloseTriggerNotMatched();
        }

        // execute close
        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(
            userPosition.pairId,
            userPosition.vaultId,
            -vault.openPosition.perp.amount,
            -vault.openPosition.sqrtPerp.amount,
            abi.encode(CallbackData(triggerType, userPosition.owner, 0))
        );

        if (tradeParams.tradeAmount == 0 && tradeParams.tradeAmountSqrt == 0) {
            revert AlreadyClosed();
        }

        tradeResult = _predyPool.trade(tradeParams, _getSettlementDataFromV3(settlementParams, msg.sender));

        SlippageLib.checkPrice(sqrtPrice, tradeResult, slippageTorelance, SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE);
    }

    function quoteTrade(GammaOrder memory gammaOrder, SettlementParamsV3 memory settlementParams) external {
        // execute trade
        _predyPool.trade(
            IPredyPool.TradeParams(
                gammaOrder.pairId,
                gammaOrder.positionId,
                gammaOrder.quantity,
                gammaOrder.quantitySqrt,
                abi.encode(
                    CallbackData(
                        GammaTradeMarketLib.CallbackType.QUOTE, gammaOrder.info.trader, gammaOrder.marginAmount
                    )
                )
            ),
            _getSettlementDataFromV3(settlementParams, msg.sender)
        );
    }

    function checkAutoHedgeAndClose(uint256 positionId)
        external
        view
        returns (bool hedgeRequired, bool closeRequired, uint256 resultPositionId)
    {
        GammaTradeMarketLib.UserPosition memory userPosition = userPositions[positionId];

        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        if (vault.openPosition.perp.amount == 0 && vault.openPosition.sqrtPerp.amount == 0) {
            return (false, false, positionId);
        }

        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        (hedgeRequired,,) = GammaTradeMarketLib.validateHedgeCondition(userPosition, sqrtPrice);

        (closeRequired,,) = GammaTradeMarketLib.validateCloseCondition(userPosition, sqrtPrice);

        resultPositionId = positionId;
    }

    struct UserPositionResult {
        GammaTradeMarketLib.UserPosition userPosition;
        IPredyPool.VaultStatus vaultStatus;
        DataType.Vault vault;
    }

    function getUserPositions(address owner) external returns (UserPositionResult[] memory) {
        uint256[] memory userPositionIDs = positionIDs[owner];

        UserPositionResult[] memory results = new UserPositionResult[](userPositionIDs.length);

        for (uint64 i = 0; i < userPositionIDs.length; i++) {
            uint256 positionId = userPositionIDs[i];

            results[i] = _getUserPosition(positionId);
        }

        return results;
    }

    function _getUserPosition(uint256 positionId) internal returns (UserPositionResult memory result) {
        GammaTradeMarketLib.UserPosition memory userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0) {
            // if user has no position, return empty vault status and vault
            return result;
        }

        return UserPositionResult(
            userPosition, _quoter.quoteVaultStatus(userPosition.vaultId), _predyPool.getVault(userPosition.vaultId)
        );
    }

    function _addPositionIndex(address trader, uint256 newPositionId) internal {
        positionIDs[trader].addItem(newPositionId);
    }

    function removePosition(uint256 positionId) external onlyFiller {
        DataType.Vault memory vault = _predyPool.getVault(userPositions[positionId].vaultId);

        if (vault.margin != 0 || vault.openPosition.perp.amount != 0 || vault.openPosition.sqrtPerp.amount != 0) {
            revert PositionIsNotClosed();
        }

        _removePosition(positionId);
    }

    function _removePosition(uint256 positionId) internal {
        address trader = userPositions[positionId].owner;

        positionIDs[trader].removeItem(positionId);
    }

    function _getOrInitPosition(uint256 positionId, bool isCreatedNew, address trader, uint64 pairId)
        internal
        returns (GammaTradeMarketLib.UserPosition storage userPosition)
    {
        userPosition = userPositions[positionId];

        if (isCreatedNew) {
            userPosition.vaultId = positionId;
            userPosition.owner = trader;
            userPosition.pairId = pairId;
            return userPosition;
        }

        if (positionId == 0 || userPosition.vaultId == 0) {
            revert PositionNotFound();
        }

        if (userPosition.owner != trader) {
            revert SignerIsNotPositionOwner();
        }

        if (userPosition.pairId != pairId) {
            revert PositionHasDifferentPairId();
        }

        return userPosition;
    }

    function _saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)
        internal
    {
        if (GammaTradeMarketLib.saveUserPosition(userPosition, modifyInfo)) {
            emit GammaPositionModified(userPosition.owner, userPosition.pairId, userPosition.vaultId, modifyInfo);
        }
    }

    function _verifyOrder(ResolvedOrder memory order) internal {
        order.validate();

        _permit2.permitWitnessTransferFrom(
            order.toPermit(),
            order.transferDetails(address(this)),
            order.info.trader,
            order.hash,
            GammaOrderLib.PERMIT2_ORDER_TYPE,
            order.sig
        );
    }
}
