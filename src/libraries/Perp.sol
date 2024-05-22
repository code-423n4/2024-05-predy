// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@solmate/src/utils/SafeCastLib.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import "./ScaledAsset.sol";
import "./InterestRateModel.sol";
import "./PremiumCurveModel.sol";
import "./Constants.sol";
import {DataType} from "./DataType.sol";
import "./UniHelper.sol";
import "./math/LPMath.sol";
import "./math/Math.sol";
import "./Reallocation.sol";

/// @title Perp library to calculate perp positions
library Perp {
    using ScaledAsset for ScaledAsset.AssetStatus;
    using SafeCastLib for uint256;
    using Math for int256;

    /// @notice Thrown when the supply of 2*squart can not cover borrow
    error SqrtAssetCanNotCoverBorrow();

    /// @notice Thrown when the available liquidity is not enough to withdraw
    error NoCFMMLiquidityError();

    /// @notice Thrown when the LP position is out of range
    error OutOfRangeError();

    struct AssetPoolStatus {
        address token;
        address supplyTokenAddress;
        ScaledAsset.AssetStatus tokenStatus;
        InterestRateModel.IRMParams irmParams;
        uint256 accumulatedProtocolRevenue;
        uint256 accumulatedCreatorRevenue;
    }

    struct AssetRiskParams {
        uint128 riskRatio;
        uint128 debtRiskRatio;
        int24 rangeSize;
        int24 rebalanceThreshold;
        uint64 minSlippage;
        uint64 maxSlippage;
    }

    struct PositionStatus {
        int256 amount;
        int256 entryValue;
    }

    struct SqrtPositionStatus {
        int256 amount;
        int256 entryValue;
        int256 quoteRebalanceEntryValue;
        int256 baseRebalanceEntryValue;
        uint256 entryTradeFee0;
        uint256 entryTradeFee1;
    }

    struct UpdatePerpParams {
        int256 tradeAmount;
        int256 stableAmount;
    }

    struct UpdateSqrtPerpParams {
        int256 tradeSqrtAmount;
        int256 stableAmount;
    }

    struct SqrtPerpAssetStatus {
        address uniswapPool;
        int24 tickLower;
        int24 tickUpper;
        uint64 numRebalance;
        uint256 totalAmount;
        uint256 borrowedAmount;
        uint256 lastRebalanceTotalSquartAmount;
        uint256 lastFee0Growth;
        uint256 lastFee1Growth;
        uint256 borrowPremium0Growth;
        uint256 borrowPremium1Growth;
        uint256 fee0Growth;
        uint256 fee1Growth;
        ScaledAsset.UserStatus rebalancePositionBase;
        ScaledAsset.UserStatus rebalancePositionQuote;
        int256 rebalanceInterestGrowthBase;
        int256 rebalanceInterestGrowthQuote;
    }

    struct UserStatus {
        uint256 pairId;
        int24 rebalanceLastTickLower;
        int24 rebalanceLastTickUpper;
        uint64 lastNumRebalance;
        PositionStatus perp;
        SqrtPositionStatus sqrtPerp;
        ScaledAsset.UserStatus basePosition;
        ScaledAsset.UserStatus stablePosition;
    }

    event PremiumGrowthUpdated(
        uint256 indexed pairId,
        uint256 totalAmount,
        uint256 borrowAmount,
        uint256 fee0Growth,
        uint256 fee1Growth,
        uint256 spread
    );
    event SqrtPositionUpdated(uint256 indexed pairId, int256 open, int256 close);

    function createAssetStatus(address uniswapPool, int24 tickLower, int24 tickUpper)
        internal
        pure
        returns (SqrtPerpAssetStatus memory)
    {
        return SqrtPerpAssetStatus(
            uniswapPool,
            tickLower,
            tickUpper,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus(),
            0,
            0
        );
    }

    function createPerpUserStatus(uint64 _pairId) internal pure returns (UserStatus memory) {
        return UserStatus(
            _pairId,
            0,
            0,
            0,
            PositionStatus(0, 0),
            SqrtPositionStatus(0, 0, 0, 0, 0, 0),
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus()
        );
    }

    /// @notice Settle the interest on rebalance positions up to this block and update the rebalance fee growth value
    function updateRebalanceInterestGrowth(
        DataType.PairStatus memory _pairStatus,
        SqrtPerpAssetStatus storage _sqrtAssetStatus
    ) internal {
        // settle the interest on rebalance position
        // fee growths are scaled by 1e18
        if (_sqrtAssetStatus.lastRebalanceTotalSquartAmount > 0) {
            _sqrtAssetStatus.rebalanceInterestGrowthBase += _pairStatus.basePool.tokenStatus.settleUserFee(
                _sqrtAssetStatus.rebalancePositionBase
            ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

            _sqrtAssetStatus.rebalanceInterestGrowthQuote += _pairStatus.quotePool.tokenStatus.settleUserFee(
                _sqrtAssetStatus.rebalancePositionQuote
            ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);
        }
    }

    /**
     * @notice Reallocates LP position to be in range.
     * In case of in-range
     *   token0
     *     1/sqrt(x) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(b1)
     *   token1
     *     sqrt(x) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(a1)
     *
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *     0 -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(x)
     *   token1
     *     sqrt(b1) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(b1) - sqrt(a1) - (sqrt(x) - sqrt(a2))
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *     1/sqrt(a1) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(a1) - 1/sqrt(b1) - (1/sqrt(x) - 1/sqrt(b2))
     *   token1
     *     0 -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(x)
     */
    function reallocate(
        DataType.PairStatus storage _assetStatusUnderlying,
        SqrtPerpAssetStatus storage _sqrtAssetStatus
    ) internal returns (bool, bool, int256 deltaPositionBase, int256 deltaPositionQuote) {
        (uint160 currentSqrtPrice, int24 currentTick,,,,,) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).slot0();

        // If the current tick does not reach the threshold, then do nothing
        if (
            _sqrtAssetStatus.tickLower + _assetStatusUnderlying.riskParams.rebalanceThreshold < currentTick
                && currentTick < _sqrtAssetStatus.tickUpper - _assetStatusUnderlying.riskParams.rebalanceThreshold
        ) {
            saveLastFeeGrowth(_sqrtAssetStatus);

            return (false, false, 0, 0);
        }

        // If the total liquidity is 0, then do nothing
        uint128 totalLiquidityAmount = getAvailableLiquidityAmount(
            address(this), _sqrtAssetStatus.uniswapPool, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper
        );

        if (totalLiquidityAmount == 0) {
            (_sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper) =
                Reallocation.getNewRange(_assetStatusUnderlying, currentTick);

            saveLastFeeGrowth(_sqrtAssetStatus);

            return (false, true, 0, 0);
        }

        // if the current tick does reach the threshold, then rebalance
        int24 tick;
        bool isOutOfRange;

        if (currentTick < _sqrtAssetStatus.tickLower) {
            // lower out
            isOutOfRange = true;
            tick = _sqrtAssetStatus.tickLower;
        } else if (currentTick < _sqrtAssetStatus.tickUpper) {
            // in range
            isOutOfRange = false;
        } else {
            // upper out
            isOutOfRange = true;
            tick = _sqrtAssetStatus.tickUpper;
        }

        rebalanceForInRange(_assetStatusUnderlying, _sqrtAssetStatus, currentTick, totalLiquidityAmount);

        saveLastFeeGrowth(_sqrtAssetStatus);

        // if the current tick is out of range, then swap
        if (isOutOfRange) {
            (deltaPositionBase, deltaPositionQuote) =
                swapForOutOfRange(_assetStatusUnderlying, currentSqrtPrice, tick, totalLiquidityAmount);
        }

        return (true, true, deltaPositionBase, deltaPositionQuote);
    }

    function rebalanceForInRange(
        DataType.PairStatus storage _assetStatusUnderlying,
        SqrtPerpAssetStatus storage _sqrtAssetStatus,
        int24 _currentTick,
        uint128 _totalLiquidityAmount
    ) internal {
        (uint256 receivedAmount0, uint256 receivedAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).burn(
            _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _totalLiquidityAmount
        );

        IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).collect(
            address(this), _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, type(uint128).max, type(uint128).max
        );

        (_sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper) =
            Reallocation.getNewRange(_assetStatusUnderlying, _currentTick);

        (uint256 requiredAmount0, uint256 requiredAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).mint(
            address(this), _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _totalLiquidityAmount, ""
        );

        // these amounts are originally int256, so we can cast these to int256 safely
        updateRebalancePosition(
            _assetStatusUnderlying,
            int256(receivedAmount0) - int256(requiredAmount0),
            int256(receivedAmount1) - int256(requiredAmount1)
        );
    }

    /**
     * @notice Swaps additional token amounts for rebalance.
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *       1/sqrt(x)　- 1/sqrt(b1)
     *   token1
     *       sqrt(x) - sqrt(b1)
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *       1/sqrt(x) - 1/sqrt(a1)
     *   token1
     *       sqrt(x) - sqrt(a1)
     */
    function swapForOutOfRange(
        DataType.PairStatus storage pairStatus,
        uint160 _currentSqrtPrice,
        int24 _tick,
        uint128 _totalLiquidityAmount
    ) internal returns (int256 deltaPositionBase, int256 deltaPositionQuote) {
        uint160 tickSqrtPrice = TickMath.getSqrtRatioAtTick(_tick);

        // 1/_currentSqrtPrice - 1/tickSqrtPrice
        int256 deltaPosition0 =
            LPMath.calculateAmount0ForLiquidity(_currentSqrtPrice, tickSqrtPrice, _totalLiquidityAmount, true);

        // _currentSqrtPrice - tickSqrtPrice
        int256 deltaPosition1 =
            LPMath.calculateAmount1ForLiquidity(_currentSqrtPrice, tickSqrtPrice, _totalLiquidityAmount, true);

        if (pairStatus.isQuoteZero) {
            deltaPositionQuote = -deltaPosition0;
            deltaPositionBase = -deltaPosition1;
        } else {
            deltaPositionBase = -deltaPosition0;
            deltaPositionQuote = -deltaPosition1;
        }

        updateRebalancePosition(pairStatus, deltaPosition0, deltaPosition1);
    }

    function getAvailableLiquidityAmount(
        address _controllerAddress,
        address _uniswapPool,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint128) {
        bytes32 positionKey = PositionKey.compute(_controllerAddress, _tickLower, _tickUpper);

        (uint128 liquidity,,,,) = IUniswapV3Pool(_uniswapPool).positions(positionKey);

        return liquidity;
    }

    function settleUserBalance(DataType.PairStatus storage _pairStatus, UserStatus storage _userStatus) internal {
        (int256 deltaPositionUnderlying, int256 deltaPositionStable) =
            updateRebalanceEntry(_pairStatus.sqrtAssetStatus, _userStatus, _pairStatus.isQuoteZero);

        if (deltaPositionUnderlying == 0 && deltaPositionStable == 0) {
            return;
        }

        _userStatus.sqrtPerp.baseRebalanceEntryValue += deltaPositionUnderlying;
        _userStatus.sqrtPerp.quoteRebalanceEntryValue += deltaPositionStable;

        // already settled fee

        _pairStatus.basePool.tokenStatus.updatePosition(
            _pairStatus.sqrtAssetStatus.rebalancePositionBase, -deltaPositionUnderlying, _pairStatus.id, false
        );
        _pairStatus.quotePool.tokenStatus.updatePosition(
            _pairStatus.sqrtAssetStatus.rebalancePositionQuote, -deltaPositionStable, _pairStatus.id, true
        );

        _pairStatus.basePool.tokenStatus.updatePosition(
            _userStatus.basePosition, deltaPositionUnderlying, _pairStatus.id, false
        );
        _pairStatus.quotePool.tokenStatus.updatePosition(
            _userStatus.stablePosition, deltaPositionStable, _pairStatus.id, true
        );
    }

    function updateFeeAndPremiumGrowth(uint256 _pairId, SqrtPerpAssetStatus storage _assetStatus) internal {
        if (_assetStatus.totalAmount == 0) {
            return;
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            UniHelper.getFeeGrowthInside(_assetStatus.uniswapPool, _assetStatus.tickLower, _assetStatus.tickUpper);

        uint256 f0;
        uint256 f1;

        // overflow of feeGrowth is unchecked in Uniswap V3
        unchecked {
            f0 = feeGrowthInside0X128 - _assetStatus.lastFee0Growth;
            f1 = feeGrowthInside1X128 - _assetStatus.lastFee1Growth;
        }

        if (f0 == 0 && f1 == 0) {
            return;
        }

        uint256 utilization = getUtilizationRatio(_assetStatus);

        uint256 spreadParam = PremiumCurveModel.calculatePremiumCurve(utilization);

        _assetStatus.fee0Growth += FullMath.mulDiv(
            f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount
        );
        _assetStatus.fee1Growth += FullMath.mulDiv(
            f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount
        );

        _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);
        _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

        _assetStatus.lastFee0Growth = feeGrowthInside0X128;
        _assetStatus.lastFee1Growth = feeGrowthInside1X128;

        emit PremiumGrowthUpdated(_pairId, _assetStatus.totalAmount, _assetStatus.borrowedAmount, f0, f1, spreadParam);
    }

    function saveLastFeeGrowth(SqrtPerpAssetStatus storage _assetStatus) internal {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            UniHelper.getFeeGrowthInside(_assetStatus.uniswapPool, _assetStatus.tickLower, _assetStatus.tickUpper);

        _assetStatus.lastFee0Growth = feeGrowthInside0X128;
        _assetStatus.lastFee1Growth = feeGrowthInside1X128;
    }

    /**
     * @notice Computes reuired amounts to increase or decrease sqrt positions.
     * (L/sqrt{x}, L * sqrt{x})
     */
    function computeRequiredAmounts(
        SqrtPerpAssetStatus storage _sqrtAssetStatus,
        bool _isQuoteZero,
        UserStatus memory _userStatus,
        int256 _tradeSqrtAmount
    ) internal returns (int256 requiredAmountUnderlying, int256 requiredAmountStable) {
        if (_tradeSqrtAmount == 0) {
            return (0, 0);
        }

        if (!Reallocation.isInRange(_sqrtAssetStatus)) {
            revert OutOfRangeError();
        }

        int256 requiredAmount0;
        int256 requiredAmount1;

        if (_tradeSqrtAmount > 0) {
            (requiredAmount0, requiredAmount1) = increase(_sqrtAssetStatus, uint256(_tradeSqrtAmount));

            if (_sqrtAssetStatus.totalAmount == _sqrtAssetStatus.borrowedAmount) {
                // if available liquidity was 0 and added first liquidity then update last fee growth
                saveLastFeeGrowth(_sqrtAssetStatus);
            }
        } else if (_tradeSqrtAmount < 0) {
            (requiredAmount0, requiredAmount1) = decrease(_sqrtAssetStatus, uint256(-_tradeSqrtAmount));
        }

        if (_isQuoteZero) {
            requiredAmountStable = requiredAmount0;
            requiredAmountUnderlying = requiredAmount1;
        } else {
            requiredAmountStable = requiredAmount1;
            requiredAmountUnderlying = requiredAmount0;
        }

        (int256 offsetUnderlying, int256 offsetStable) = calculateSqrtPerpOffset(
            _userStatus, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _tradeSqrtAmount, _isQuoteZero
        );

        requiredAmountUnderlying -= offsetUnderlying;
        requiredAmountStable -= offsetStable;
    }

    function updatePosition(
        DataType.PairStatus storage _pairStatus,
        UserStatus storage _userStatus,
        UpdatePerpParams memory _updatePerpParams,
        UpdateSqrtPerpParams memory _updateSqrtPerpParams
    ) internal returns (IPredyPool.Payoff memory payoff) {
        (payoff.perpEntryUpdate, payoff.perpPayoff) = calculateEntry(
            _userStatus.perp.amount,
            _userStatus.perp.entryValue,
            _updatePerpParams.tradeAmount,
            _updatePerpParams.stableAmount
        );

        (payoff.sqrtRebalanceEntryUpdateUnderlying, payoff.sqrtRebalanceEntryUpdateStable) = calculateSqrtPerpOffset(
            _userStatus,
            _pairStatus.sqrtAssetStatus.tickLower,
            _pairStatus.sqrtAssetStatus.tickUpper,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _pairStatus.isQuoteZero
        );

        (payoff.sqrtEntryUpdate, payoff.sqrtPayoff) = calculateEntry(
            _userStatus.sqrtPerp.amount,
            _userStatus.sqrtPerp.entryValue,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _updateSqrtPerpParams.stableAmount
        );

        _userStatus.perp.amount += _updatePerpParams.tradeAmount;

        // Update entry value
        _userStatus.perp.entryValue += payoff.perpEntryUpdate;
        _userStatus.sqrtPerp.entryValue += payoff.sqrtEntryUpdate;
        _userStatus.sqrtPerp.quoteRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateStable;
        _userStatus.sqrtPerp.baseRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateUnderlying;

        // Update sqrt position
        updateSqrtPosition(
            _pairStatus.id, _pairStatus.sqrtAssetStatus, _userStatus, _updateSqrtPerpParams.tradeSqrtAmount
        );

        _pairStatus.basePool.tokenStatus.updatePosition(
            _userStatus.basePosition,
            _updatePerpParams.tradeAmount + payoff.sqrtRebalanceEntryUpdateUnderlying,
            _pairStatus.id,
            false
        );

        _pairStatus.quotePool.tokenStatus.updatePosition(
            _userStatus.stablePosition,
            payoff.perpEntryUpdate + payoff.sqrtEntryUpdate + payoff.sqrtRebalanceEntryUpdateStable,
            _pairStatus.id,
            true
        );
    }

    function updateSqrtPosition(
        uint256 _pairId,
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        int256 _amount
    ) internal {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _amount >= 0) {
            openAmount = _amount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _amount.abs()) {
                closeAmount = _amount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _amount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (_assetStatus.totalAmount == _assetStatus.borrowedAmount) {
            // if available liquidity was 0 and added first liquidity then update last fee growth
            saveLastFeeGrowth(_assetStatus);
        }

        if (closeAmount > 0) {
            _assetStatus.borrowedAmount -= uint256(closeAmount);
        } else if (closeAmount < 0) {
            if (getAvailableSqrtAmount(_assetStatus, true) < uint256(-closeAmount)) {
                revert SqrtAssetCanNotCoverBorrow();
            }
            _assetStatus.totalAmount -= uint256(-closeAmount);
        }

        if (openAmount > 0) {
            _assetStatus.totalAmount += uint256(openAmount);

            _userStatus.sqrtPerp.entryTradeFee0 = _assetStatus.fee0Growth;
            _userStatus.sqrtPerp.entryTradeFee1 = _assetStatus.fee1Growth;
        } else if (openAmount < 0) {
            if (getAvailableSqrtAmount(_assetStatus, false) < uint256(-openAmount)) {
                revert SqrtAssetCanNotCoverBorrow();
            }

            _assetStatus.borrowedAmount += uint256(-openAmount);

            _userStatus.sqrtPerp.entryTradeFee0 = _assetStatus.borrowPremium0Growth;
            _userStatus.sqrtPerp.entryTradeFee1 = _assetStatus.borrowPremium1Growth;
        }

        _userStatus.sqrtPerp.amount += _amount;

        emit SqrtPositionUpdated(_pairId, openAmount, closeAmount);
    }

    /**
     * @notice Gets available sqrt amount
     * max available amount is 98% of total amount
     */
    function getAvailableSqrtAmount(SqrtPerpAssetStatus memory _assetStatus, bool _isWithdraw)
        internal
        pure
        returns (uint256)
    {
        uint256 buffer = Math.max(_assetStatus.totalAmount / 50, Constants.MIN_LIQUIDITY);
        uint256 available = _assetStatus.totalAmount - _assetStatus.borrowedAmount;

        if (_isWithdraw && _assetStatus.borrowedAmount == 0) {
            return available;
        }

        if (available >= buffer) {
            return available - buffer;
        } else {
            return 0;
        }
    }

    function getUtilizationRatio(SqrtPerpAssetStatus memory _assetStatus) internal pure returns (uint256) {
        if (_assetStatus.totalAmount == 0) {
            return 0;
        }

        uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

        if (utilization > 1e18) {
            return 1e18;
        }

        return utilization;
    }

    function updateRebalanceEntry(
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        bool _isQuoteZero
    ) internal returns (int256 rebalancePositionUpdateUnderlying, int256 rebalancePositionUpdateStable) {
        // Rebalance position should be over repayed or deposited.
        // rebalancePositionUpdate values must be rounded down to a smaller value.

        if (_userStatus.sqrtPerp.amount == 0) {
            _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
            _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

            return (0, 0);
        }

        if (_assetStatus.lastRebalanceTotalSquartAmount == 0) {
            // last user who settles rebalance position
            _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
            _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

            return
                (_assetStatus.rebalancePositionBase.positionAmount, _assetStatus.rebalancePositionQuote.positionAmount);
        }

        int256 deltaPosition0 = LPMath.calculateAmount0ForLiquidityWithTicks(
            _assetStatus.tickUpper,
            _userStatus.rebalanceLastTickUpper,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        int256 deltaPosition1 = LPMath.calculateAmount1ForLiquidityWithTicks(
            _assetStatus.tickLower,
            _userStatus.rebalanceLastTickLower,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
        _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

        if (_userStatus.sqrtPerp.amount < 0) {
            deltaPosition0 = -deltaPosition0;
            deltaPosition1 = -deltaPosition1;
        }

        if (_isQuoteZero) {
            rebalancePositionUpdateUnderlying = deltaPosition1;
            rebalancePositionUpdateStable = deltaPosition0;
        } else {
            rebalancePositionUpdateUnderlying = deltaPosition0;
            rebalancePositionUpdateStable = deltaPosition1;
        }
    }

    function calculateEntry(int256 _positionAmount, int256 _entryValue, int256 _tradeAmount, int256 _valueUpdate)
        internal
        pure
        returns (int256 deltaEntry, int256 payoff)
    {
        if (_tradeAmount == 0) {
            return (0, 0);
        }

        if (_positionAmount * _tradeAmount >= 0) {
            // open position
            deltaEntry = _valueUpdate;
        } else {
            if (_positionAmount.abs() >= _tradeAmount.abs()) {
                // close position

                int256 closeStableAmount = _entryValue * _tradeAmount / _positionAmount;

                deltaEntry = closeStableAmount;
                payoff = _valueUpdate - closeStableAmount;
            } else {
                // close full and open position

                int256 closeStableAmount = -_entryValue;
                int256 openStableAmount = _valueUpdate * (_positionAmount + _tradeAmount) / _tradeAmount;

                deltaEntry = closeStableAmount + openStableAmount;
                payoff = _valueUpdate - closeStableAmount - openStableAmount;
            }
        }
    }

    // private functions

    function increase(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 requiredAmount0, int256 requiredAmount1)
    {
        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).mint(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128(), ""
        );

        requiredAmount0 = -SafeCast.toInt256(amount0);
        requiredAmount1 = -SafeCast.toInt256(amount1);
    }

    function decrease(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 receivedAmount0, int256 receivedAmount1)
    {
        if (_assetStatus.totalAmount - _assetStatus.borrowedAmount < _liquidityAmount) {
            revert NoCFMMLiquidityError();
        }

        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).burn(
            _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128()
        );

        // collect burned token amounts
        IUniswapV3Pool(_assetStatus.uniswapPool).collect(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, type(uint128).max, type(uint128).max
        );

        receivedAmount0 = SafeCast.toInt256(amount0);
        receivedAmount1 = SafeCast.toInt256(amount1);
    }

    /**
     * @notice Calculates sqrt perp offset
     * open: (L/sqrt{b}, L * sqrt{a})
     * close: (-L * e0, -L * e1)
     */
    function calculateSqrtPerpOffset(
        UserStatus memory _userStatus,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _tradeSqrtAmount,
        bool _isQuoteZero
    ) internal pure returns (int256 offsetUnderlying, int256 offsetStable) {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _tradeSqrtAmount >= 0) {
            openAmount = _tradeSqrtAmount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _tradeSqrtAmount.abs()) {
                closeAmount = _tradeSqrtAmount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _tradeSqrtAmount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (openAmount != 0) {
            // L / sqrt(b)
            offsetUnderlying = LPMath.calculateAmount0OffsetWithTick(_tickUpper, openAmount.abs(), openAmount < 0);

            // L * sqrt(a)
            offsetStable = LPMath.calculateAmount1OffsetWithTick(_tickLower, openAmount.abs(), openAmount < 0);

            if (openAmount < 0) {
                offsetUnderlying = -offsetUnderlying;
                offsetStable = -offsetStable;
            }

            if (_isQuoteZero) {
                // Swap if the pool is Stable-Underlying pair
                (offsetUnderlying, offsetStable) = (offsetStable, offsetUnderlying);
            }
        }

        if (closeAmount != 0) {
            offsetStable += closeAmount * _userStatus.sqrtPerp.quoteRebalanceEntryValue / _userStatus.sqrtPerp.amount;
            offsetUnderlying += closeAmount * _userStatus.sqrtPerp.baseRebalanceEntryValue / _userStatus.sqrtPerp.amount;
        }
    }

    function updateRebalancePosition(
        DataType.PairStatus storage _pairStatus,
        int256 _updateAmount0,
        int256 _updateAmount1
    ) internal {
        SqrtPerpAssetStatus storage sqrtAsset = _pairStatus.sqrtAssetStatus;

        if (_pairStatus.isQuoteZero) {
            _pairStatus.quotePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionQuote, _updateAmount0, _pairStatus.id, true
            );
            _pairStatus.basePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionBase, _updateAmount1, _pairStatus.id, false
            );
        } else {
            _pairStatus.basePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionBase, _updateAmount0, _pairStatus.id, false
            );
            _pairStatus.quotePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionQuote, _updateAmount1, _pairStatus.id, true
            );
        }
    }

    /// @notice called after reallocation
    function finalizeReallocation(SqrtPerpAssetStatus storage sqrtPerpStatus) internal {
        // LastRebalanceTotalSquartAmount is the total amount of positions that will have to pay rebalancing interest in the future
        sqrtPerpStatus.lastRebalanceTotalSquartAmount = sqrtPerpStatus.totalAmount + sqrtPerpStatus.borrowedAmount;
        sqrtPerpStatus.numRebalance++;
    }
}
