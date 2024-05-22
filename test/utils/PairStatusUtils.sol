// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../../src/libraries/Perp.sol";
import "../../src/libraries/ScaledAsset.sol";
import "../../src/libraries/InterestRateModel.sol";

contract PairStatusUtils {
    uint128 internal constant _RISK_RATIO = 109544511;
    uint128 internal constant _BASE_MIN_COLLATERAL_WITH_DEBT = 2000;

    function createAssetStatus(uint256 pairId, address marginId, address _weth, address _uniswapPool)
        internal
        view
        returns (DataType.PairStatus memory assetStatus)
    {
        assetStatus = DataType.PairStatus(
            pairId,
            marginId,
            address(0),
            Perp.AssetPoolStatus(
                address(0),
                address(0),
                ScaledAsset.createAssetStatus(),
                InterestRateModel.IRMParams(0, 9 * 1e17, 1e17, 1e18),
                0,
                0
            ),
            Perp.AssetPoolStatus(
                _weth,
                address(0),
                ScaledAsset.createAssetStatus(),
                InterestRateModel.IRMParams(0, 9 * 1e17, 1e17, 1e18),
                0,
                0
            ),
            Perp.AssetRiskParams(_RISK_RATIO, _BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 10050, 10500),
            Perp.createAssetStatus(_uniswapPool, -100, 100),
            address(0),
            false,
            false,
            0,
            block.timestamp
        );
    }
}
