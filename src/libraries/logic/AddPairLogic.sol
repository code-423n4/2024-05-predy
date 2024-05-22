// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {Perp} from "../Perp.sol";
import {Constants} from "../Constants.sol";
import {DataType} from "../DataType.sol";
import {InterestRateModel} from "../InterestRateModel.sol";
import {ScaledAsset} from "../ScaledAsset.sol";
import {SupplyToken} from "../../tokenization/SupplyToken.sol";
import {GlobalDataLibrary} from "../../types/GlobalData.sol";

library AddPairLogic {
    struct AddPairParams {
        address quoteToken;
        address poolOwner;
        address uniswapPool;
        address priceFeed;
        bool allowlistEnabled;
        uint8 fee;
        Perp.AssetRiskParams assetRiskParams;
        InterestRateModel.IRMParams quoteIrmParams;
        InterestRateModel.IRMParams baseIrmParams;
    }

    error InvalidUniswapPool();

    event PairAdded(uint256 pairId, address quoteToken, address uniswapPool);
    event AssetRiskParamsUpdated(uint256 pairId, Perp.AssetRiskParams riskParams);
    event IRMParamsUpdated(
        uint256 pairId, InterestRateModel.IRMParams quoteIrmParams, InterestRateModel.IRMParams baseIrmParams
    );
    event FeeRatioUpdated(uint256 pairId, uint8 feeRatio);
    event PoolOwnerUpdated(uint256 pairId, address poolOwner);
    event PriceOracleUpdated(uint256 pairId, address priceOracle);

    /**
     * @notice Initialized global data counts
     * @param global Global data
     */
    function initializeGlobalData(GlobalDataLibrary.GlobalData storage global, address uniswapFactory) external {
        global.pairsCount = 1;
        global.vaultCount = 1;
        global.uniswapFactory = uniswapFactory;
    }

    /**
     * @notice Adds token pair
     */
    function addPair(
        GlobalDataLibrary.GlobalData storage _global,
        mapping(address => bool) storage allowedUniswapPools,
        AddPairParams memory _addPairParam
    ) external returns (uint256 pairId) {
        pairId = _global.pairsCount;

        require(pairId < Constants.MAX_PAIRS, "MAXP");

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(_addPairParam.uniswapPool);

        address stableTokenAddress = _addPairParam.quoteToken;

        IUniswapV3Factory uniswapV3Factory = IUniswapV3Factory(_global.uniswapFactory);

        // check the uniswap pool is registered in UniswapV3Factory
        if (
            uniswapV3Factory.getPool(uniswapPool.token0(), uniswapPool.token1(), uniswapPool.fee())
                != _addPairParam.uniswapPool
        ) {
            revert InvalidUniswapPool();
        }

        require(uniswapPool.token0() == stableTokenAddress || uniswapPool.token1() == stableTokenAddress, "C3");

        bool isQuoteZero = uniswapPool.token0() == stableTokenAddress;

        _storePairStatus(
            stableTokenAddress,
            _global.pairs,
            pairId,
            isQuoteZero ? uniswapPool.token1() : uniswapPool.token0(),
            isQuoteZero,
            _addPairParam
        );

        allowedUniswapPools[_addPairParam.uniswapPool] = true;

        _global.pairsCount++;

        emit PairAdded(pairId, _addPairParam.quoteToken, _addPairParam.uniswapPool);
    }

    function updateFeeRatio(DataType.PairStatus storage _pairStatus, uint8 _feeRatio) external {
        validateFeeRatio(_feeRatio);

        _pairStatus.feeRatio = _feeRatio;

        emit FeeRatioUpdated(_pairStatus.id, _feeRatio);
    }

    function updatePoolOwner(DataType.PairStatus storage _pairStatus, address _poolOwner) external {
        validatePoolOwner(_poolOwner);

        _pairStatus.poolOwner = _poolOwner;

        emit PoolOwnerUpdated(_pairStatus.id, _poolOwner);
    }

    function updatePriceOracle(DataType.PairStatus storage _pairStatus, address _priceOracle) external {
        _pairStatus.priceFeed = _priceOracle;

        emit PriceOracleUpdated(_pairStatus.id, _priceOracle);
    }

    function updateAssetRiskParams(DataType.PairStatus storage _pairStatus, Perp.AssetRiskParams memory _riskParams)
        external
    {
        validateRiskParams(_riskParams);

        _pairStatus.riskParams = _riskParams;

        emit AssetRiskParamsUpdated(_pairStatus.id, _riskParams);
    }

    function updateIRMParams(
        DataType.PairStatus storage _pairStatus,
        InterestRateModel.IRMParams memory _quoteIrmParams,
        InterestRateModel.IRMParams memory _baseIrmParams
    ) external {
        validateIRMParams(_quoteIrmParams);
        validateIRMParams(_baseIrmParams);

        _pairStatus.quotePool.irmParams = _quoteIrmParams;
        _pairStatus.basePool.irmParams = _baseIrmParams;

        emit IRMParamsUpdated(_pairStatus.id, _quoteIrmParams, _baseIrmParams);
    }

    function _storePairStatus(
        address quoteToken,
        mapping(uint256 => DataType.PairStatus) storage _pairs,
        uint256 _pairId,
        address _tokenAddress,
        bool _isQuoteZero,
        AddPairParams memory _addPairParam
    ) internal {
        validateRiskParams(_addPairParam.assetRiskParams);
        validateFeeRatio(_addPairParam.fee);

        require(_pairs[_pairId].id == 0, "AAA");

        _pairs[_pairId] = DataType.PairStatus(
            _pairId,
            quoteToken,
            _addPairParam.poolOwner,
            Perp.AssetPoolStatus(
                quoteToken,
                deploySupplyToken(quoteToken),
                ScaledAsset.createAssetStatus(),
                _addPairParam.quoteIrmParams,
                0,
                0
            ),
            Perp.AssetPoolStatus(
                _tokenAddress,
                deploySupplyToken(_tokenAddress),
                ScaledAsset.createAssetStatus(),
                _addPairParam.baseIrmParams,
                0,
                0
            ),
            _addPairParam.assetRiskParams,
            Perp.createAssetStatus(
                _addPairParam.uniswapPool,
                -_addPairParam.assetRiskParams.rangeSize,
                _addPairParam.assetRiskParams.rangeSize
            ),
            _addPairParam.priceFeed,
            _isQuoteZero,
            _addPairParam.allowlistEnabled,
            _addPairParam.fee,
            block.timestamp
        );

        emit AssetRiskParamsUpdated(_pairId, _addPairParam.assetRiskParams);
        emit IRMParamsUpdated(_pairId, _addPairParam.quoteIrmParams, _addPairParam.baseIrmParams);
    }

    function deploySupplyToken(address _tokenAddress) internal returns (address) {
        IERC20Metadata erc20 = IERC20Metadata(_tokenAddress);

        return address(
            new SupplyToken(
                address(this),
                string.concat("Predy6-Supply-", erc20.name()),
                string.concat("p", erc20.symbol()),
                erc20.decimals()
            )
        );
    }

    function validateFeeRatio(uint8 _fee) internal pure {
        require(_fee <= 20, "FEE");
    }

    function validatePoolOwner(address _poolOwner) internal pure {
        require(_poolOwner != address(0), "ADDZ");
    }

    function validateRiskParams(Perp.AssetRiskParams memory _assetRiskParams) internal pure {
        require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

        require(_assetRiskParams.rangeSize > 0 && _assetRiskParams.rebalanceThreshold > 0, "C0");
    }

    function validateIRMParams(InterestRateModel.IRMParams memory _irmParams) internal pure {
        require(
            _irmParams.baseRate <= 1e18 && _irmParams.kinkRate <= 1e18 && _irmParams.slope1 <= 1e18
                && _irmParams.slope2 <= 10 * 1e18,
            "C4"
        );
    }
}
