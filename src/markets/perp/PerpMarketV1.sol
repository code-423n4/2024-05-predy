// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "../../interfaces/IPredyPool.sol";
import {BaseMarketUpgradable} from "../../base/BaseMarketUpgradable.sol";
import {BaseHookCallbackUpgradable} from "../../base/BaseHookCallbackUpgradable.sol";
import "../../libraries/orders/Permit2Lib.sol";
import "../../libraries/orders/ResolvedOrder.sol";
import {SlippageLib} from "../../libraries/SlippageLib.sol";
import {PositionCalculator} from "../../libraries/PositionCalculator.sol";
import {Constants} from "../../libraries/Constants.sol";
import {Perp} from "../../libraries/Perp.sol";
import {Bps} from "../../libraries/math/Bps.sol";
import {Math} from "../../libraries/math/Math.sol";
import "./PerpOrder.sol";
import "./PerpOrderV3.sol";
import {PredyPoolQuoter} from "../../lens/PredyPoolQuoter.sol";
import {SettlementCallbackLib} from "../../base/SettlementCallbackLib.sol";
import {PerpMarketLib} from "./PerpMarketLib.sol";

/**
 * @notice Perp market contract
 */
contract PerpMarketV1 is BaseMarketUpgradable, ReentrancyGuardUpgradeable {
    using ResolvedOrderLib for ResolvedOrder;
    using PerpOrderLib for PerpOrder;
    using Permit2Lib for ResolvedOrder;
    using SafeTransferLib for ERC20;
    using SafeCast for uint256;

    error TPSLConditionDoesNotMatch();

    error UpdateMarginMustNotBePositive();

    error AmountIsZero();

    struct UserPosition {
        uint256 vaultId;
        uint256 takeProfitPrice;
        uint256 stopLossPrice;
        uint64 slippageTolerance;
        uint8 lastLeverage;
    }

    enum CallbackSource {
        TRADE,
        TRADE3,
        QUOTE,
        QUOTE3
    }

    struct CallbackData {
        CallbackSource callbackSource;
        address trader;
        int256 marginAmountUpdate;
        uint8 leverage;
        ResolvedOrder resolvedOrder;
        uint64 orderId;
    }

    IPermit2 private _permit2;

    mapping(address owner => mapping(uint256 pairId => UserPosition)) public userPositions;

    event PerpTraded(
        address indexed trader,
        uint256 pairId,
        uint256 vaultId,
        int256 tradeAmount,
        IPredyPool.Payoff payoff,
        int256 fee,
        int256 marginAmount
    );
    event PerpTraded2(
        address indexed trader,
        uint256 pairId,
        uint256 vaultId,
        int256 tradeAmount,
        IPredyPool.Payoff payoff,
        int256 fee,
        int256 marginAmount,
        uint64 orderId
    );

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

        if (callbackData.callbackSource == CallbackSource.QUOTE) {
            _revertTradeResult(tradeResult);
        } else if (callbackData.callbackSource == CallbackSource.QUOTE3) {
            _revertTradeResult(tradeResult);
        } else if (callbackData.callbackSource == CallbackSource.TRADE3) {
            int256 marginAmountUpdate =
                _calculateInitialMargin(tradeParams.vaultId, tradeParams.pairId, callbackData.leverage);

            uint256 cost = 0;

            if (marginAmountUpdate > 0) {
                cost = uint256(marginAmountUpdate);
            }

            _verifyOrderV3(callbackData.resolvedOrder, cost);

            if (marginAmountUpdate > 0) {
                quoteToken.safeTransfer(address(_predyPool), uint256(marginAmountUpdate));
            } else if (marginAmountUpdate < 0) {
                _predyPool.take(true, callbackData.trader, uint256(-marginAmountUpdate));
            }

            emit PerpTraded2(
                callbackData.trader,
                tradeParams.pairId,
                tradeResult.vaultId,
                tradeParams.tradeAmount,
                tradeResult.payoff,
                tradeResult.fee,
                marginAmountUpdate,
                callbackData.orderId
            );
        }
    }

    /**
     * @notice Verifies signature of the order_v3 and executes trade
     * @param order The order signed by trader
     * @param settlementParams The route of settlement created by filler
     */
    function executeOrderV3(SignedOrder memory order, SettlementParamsV3 memory settlementParams)
        external
        nonReentrant
        returns (IPredyPool.TradeResult memory)
    {
        PerpOrderV3 memory perpOrder = abi.decode(order.order, (PerpOrderV3));

        return _executeOrderV3(perpOrder, order.sig, settlementParams, 0);
    }

    function _executeOrderV3(
        PerpOrderV3 memory perpOrder,
        bytes memory sig,
        SettlementParamsV3 memory settlementParams,
        uint64 orderId
    ) internal returns (IPredyPool.TradeResult memory tradeResult) {
        ResolvedOrder memory resolvedOrder = PerpOrderV3Lib.resolve(perpOrder, sig);

        _validateQuoteTokenAddress(perpOrder.pairId, perpOrder.entryTokenAddress);

        UserPosition storage userPosition = userPositions[perpOrder.info.trader][perpOrder.pairId];

        userPosition.lastLeverage = perpOrder.leverage;

        int256 tradeAmount = PerpMarketLib.getFinalTradeAmount(
            _predyPool.getVault(userPosition.vaultId).openPosition.perp.amount,
            perpOrder.side,
            perpOrder.quantity,
            perpOrder.reduceOnly,
            perpOrder.closePosition
        );

        if (tradeAmount == 0) {
            revert AmountIsZero();
        }

        tradeResult = _predyPool.trade(
            IPredyPool.TradeParams(
                perpOrder.pairId,
                userPosition.vaultId,
                tradeAmount,
                0,
                abi.encode(
                    CallbackData(
                        CallbackSource.TRADE3, perpOrder.info.trader, 0, perpOrder.leverage, resolvedOrder, orderId
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

        if (userPosition.vaultId == 0) {
            userPosition.vaultId = tradeResult.vaultId;

            _predyPool.updateRecepient(tradeResult.vaultId, perpOrder.info.trader);
        }

        PerpMarketLib.validateTrade(
            tradeResult, tradeAmount, perpOrder.limitPrice, perpOrder.stopPrice, perpOrder.auctionData
        );

        return tradeResult;
    }

    function _calculateInitialMargin(uint256 vaultId, uint256 pairId, uint256 leverage)
        internal
        view
        returns (int256)
    {
        DataType.Vault memory vault = _predyPool.getVault(vaultId);

        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(pairId);

        uint256 price = Math.calSqrtPriceToPrice(sqrtPrice);

        uint256 netValue = _calculateNetValue(vault, price);

        return (netValue / leverage).toInt256() - _calculatePositionValue(vault, sqrtPrice);
    }

    function _calculateNetValue(DataType.Vault memory vault, uint256 price) internal pure returns (uint256) {
        int256 positionAmount = vault.openPosition.perp.amount;

        return Math.abs(positionAmount) * price / Constants.Q96;
    }

    function _calculatePositionValue(DataType.Vault memory vault, uint256 sqrtPrice) internal pure returns (int256) {
        return PositionCalculator.calculateValue(sqrtPrice, PositionCalculator.getPosition(vault.openPosition))
            + vault.margin;
    }

    function getUserPosition(address owner, uint256 pairId)
        external
        returns (
            UserPosition memory userPosition,
            IPredyPool.VaultStatus memory vaultStatus,
            DataType.Vault memory vault
        )
    {
        userPosition = userPositions[owner][pairId];

        if (userPosition.vaultId == 0) {
            // if user has no position, return empty vault status and vault
            return (userPosition, vaultStatus, vault);
        }

        return (userPosition, _quoter.quoteVaultStatus(userPosition.vaultId), _predyPool.getVault(userPosition.vaultId));
    }

    function _saveUserPosition(UserPosition storage userPosition, PerpOrder memory perpOrder) internal {
        require(perpOrder.slippageTolerance <= Bps.ONE);

        userPosition.takeProfitPrice = perpOrder.takeProfitPrice;
        userPosition.stopLossPrice = perpOrder.stopLossPrice;
        userPosition.slippageTolerance = perpOrder.slippageTolerance;
        userPosition.lastLeverage = perpOrder.leverage;
    }

    /// @notice Estimate transaction results and return with revert message
    function quoteExecuteOrderV3(
        PerpOrderV3 memory perpOrder,
        SettlementParamsV3 memory settlementParams,
        address filler
    ) external {
        UserPosition memory userPosition = userPositions[perpOrder.info.trader][perpOrder.pairId];

        int256 tradeAmount = PerpMarketLib.getFinalTradeAmount(
            _predyPool.getVault(userPosition.vaultId).openPosition.perp.amount,
            perpOrder.side,
            perpOrder.quantity,
            perpOrder.reduceOnly,
            perpOrder.closePosition
        );

        if (tradeAmount == 0) {
            revert AmountIsZero();
        }
        _predyPool.trade(
            IPredyPool.TradeParams(
                perpOrder.pairId,
                userPosition.vaultId,
                tradeAmount,
                0,
                abi.encode(
                    CallbackData(
                        CallbackSource.QUOTE3,
                        perpOrder.info.trader,
                        0,
                        perpOrder.leverage,
                        PerpOrderV3Lib.resolve(perpOrder, bytes("")),
                        0
                    )
                )
            ),
            _getSettlementDataFromV3(settlementParams, filler)
        );
    }

    function _verifyOrder(ResolvedOrder memory order, uint256 amount) internal {
        order.validate();

        _permit2.permitWitnessTransferFrom(
            order.toPermit(),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: amount}),
            order.info.trader,
            order.hash,
            PerpOrderLib.PERMIT2_ORDER_TYPE,
            order.sig
        );
    }

    function _verifyOrderV3(ResolvedOrder memory order, uint256 amount) internal {
        order.validate();

        _permit2.permitWitnessTransferFrom(
            order.toPermit(),
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: amount}),
            order.info.trader,
            order.hash,
            PerpOrderV3Lib.PERMIT2_ORDER_TYPE,
            order.sig
        );
    }
}
