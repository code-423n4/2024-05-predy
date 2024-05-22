// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DataType} from "./DataType.sol";
import "./Perp.sol";
import "./ScaledAsset.sol";

library Reallocation {
    using SafeCast for uint256;

    /**
     * @notice Gets new available range
     */
    function getNewRange(DataType.PairStatus memory _assetStatusUnderlying, int24 currentTick)
        internal
        view
        returns (int24 lower, int24 upper)
    {
        int24 tickSpacing = IUniswapV3Pool(_assetStatusUnderlying.sqrtAssetStatus.uniswapPool).tickSpacing();

        ScaledAsset.AssetStatus memory token0Status;
        ScaledAsset.AssetStatus memory token1Status;

        if (_assetStatusUnderlying.isQuoteZero) {
            token0Status = _assetStatusUnderlying.quotePool.tokenStatus;
            token1Status = _assetStatusUnderlying.basePool.tokenStatus;
        } else {
            token0Status = _assetStatusUnderlying.basePool.tokenStatus;
            token1Status = _assetStatusUnderlying.quotePool.tokenStatus;
        }

        return _getNewRange(_assetStatusUnderlying, token0Status, token1Status, currentTick, tickSpacing);
    }

    function _getNewRange(
        DataType.PairStatus memory _assetStatusUnderlying,
        ScaledAsset.AssetStatus memory _token0Status,
        ScaledAsset.AssetStatus memory _token1Status,
        int24 currentTick,
        int24 tickSpacing
    ) internal pure returns (int24 lower, int24 upper) {
        Perp.SqrtPerpAssetStatus memory sqrtAssetStatus = _assetStatusUnderlying.sqrtAssetStatus;

        lower = currentTick - _assetStatusUnderlying.riskParams.rangeSize;
        upper = currentTick + _assetStatusUnderlying.riskParams.rangeSize;

        int24 previousCenterTick = (sqrtAssetStatus.tickLower + sqrtAssetStatus.tickUpper) / 2;

        uint256 availableAmount = sqrtAssetStatus.totalAmount - sqrtAssetStatus.borrowedAmount;

        if (availableAmount > 0) {
            if (currentTick < previousCenterTick) {
                // move to lower
                int24 minLowerTick = calculateMinLowerTick(
                    sqrtAssetStatus.tickLower,
                    ScaledAsset.getAvailableCollateralValue(_token1Status),
                    availableAmount,
                    tickSpacing
                );

                if (lower < minLowerTick && minLowerTick < currentTick) {
                    lower = minLowerTick;
                    upper = lower + _assetStatusUnderlying.riskParams.rangeSize * 2;
                }
            } else {
                // move to upper
                int24 maxUpperTick = calculateMaxUpperTick(
                    sqrtAssetStatus.tickUpper,
                    ScaledAsset.getAvailableCollateralValue(_token0Status),
                    availableAmount,
                    tickSpacing
                );

                if (upper > maxUpperTick && maxUpperTick >= currentTick) {
                    upper = maxUpperTick;
                    lower = upper - _assetStatusUnderlying.riskParams.rangeSize * 2;
                }
            }
        }

        lower = calculateUsableTick(lower, tickSpacing);
        upper = calculateUsableTick(upper, tickSpacing);
    }

    /**
     * @notice Returns the flag that a tick is within a range or not
     */
    function isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus) internal view returns (bool) {
        (, int24 currentTick,,,,,) = IUniswapV3Pool(sqrtAssetStatus.uniswapPool).slot0();

        return _isInRange(sqrtAssetStatus, currentTick);
    }

    function _isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus, int24 currentTick)
        internal
        pure
        returns (bool)
    {
        return (sqrtAssetStatus.tickLower <= currentTick && currentTick < sqrtAssetStatus.tickUpper);
    }

    /**
     * @notice Normalizes a tick by tick spacing
     */
    function calculateUsableTick(int24 _tick, int24 tickSpacing) internal pure returns (int24 result) {
        require(tickSpacing > 0);

        result = _tick;

        if (result < TickMath.MIN_TICK) {
            result = TickMath.MIN_TICK;
        } else if (result > TickMath.MAX_TICK) {
            result = TickMath.MAX_TICK;
        }

        result = (result / tickSpacing) * tickSpacing;
    }

    /**
     * @notice The minimum tick that can be moved from the currentLowerTick, calculated from token1 amount
     */
    function calculateMinLowerTick(
        int24 currentLowerTick,
        uint256 available,
        uint256 liquidityAmount,
        int24 tickSpacing
    ) internal pure returns (int24 minLowerTick) {
        uint160 sqrtPrice =
            calculateAmount1ForLiquidity(TickMath.getSqrtRatioAtTick(currentLowerTick), available, liquidityAmount);

        minLowerTick = TickMath.getTickAtSqrtRatio(sqrtPrice);

        minLowerTick += tickSpacing;

        if (minLowerTick > currentLowerTick - tickSpacing) {
            minLowerTick = currentLowerTick - tickSpacing;
        }
    }

    /**
     * @notice The maximum tick that can be moved from the currentUpperTick, calculated from token0 amount
     */
    function calculateMaxUpperTick(
        int24 currentUpperTick,
        uint256 available,
        uint256 liquidityAmount,
        int24 tickSpacing
    ) internal pure returns (int24 maxUpperTick) {
        uint160 sqrtPrice =
            calculateAmount0ForLiquidity(TickMath.getSqrtRatioAtTick(currentUpperTick), available, liquidityAmount);

        maxUpperTick = TickMath.getTickAtSqrtRatio(sqrtPrice);

        maxUpperTick -= tickSpacing;

        if (maxUpperTick < currentUpperTick + tickSpacing) {
            maxUpperTick = currentUpperTick + tickSpacing;
        }
    }

    function calculateAmount1ForLiquidity(uint160 sqrtRatioA, uint256 available, uint256 liquidityAmount)
        internal
        pure
        returns (uint160)
    {
        uint160 sqrtPrice = (available * FixedPoint96.Q96 / liquidityAmount).toUint160();

        if (sqrtRatioA <= sqrtPrice + TickMath.MIN_SQRT_RATIO) {
            return TickMath.MIN_SQRT_RATIO + 1;
        }

        return sqrtRatioA - sqrtPrice;
    }

    function calculateAmount0ForLiquidity(uint160 sqrtRatioB, uint256 available, uint256 liquidityAmount)
        internal
        pure
        returns (uint160)
    {
        uint256 denominator1 = available * sqrtRatioB / FixedPoint96.Q96;

        if (liquidityAmount <= denominator1) {
            return TickMath.MAX_SQRT_RATIO - 1;
        }

        uint160 sqrtPrice = uint160(liquidityAmount * sqrtRatioB / (liquidityAmount - denominator1));

        if (sqrtPrice <= TickMath.MIN_SQRT_RATIO) {
            return TickMath.MIN_SQRT_RATIO + 1;
        }

        return sqrtPrice;
    }
}
