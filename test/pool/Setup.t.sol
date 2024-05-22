// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "../../src/PredyPool.sol";
import "../../src/libraries/InterestRateModel.sol";
import "../mocks/MockERC20.sol";
import "../mocks/TestTradeMarket.sol";
import "../../src/settlements/UniswapSettlement.sol";
import "../mocks/DebugSettlement2.sol";
import "../../src/lens/PredyPoolQuoter.sol";
import "../../src/interfaces/IFillerMarket.sol";

contract TestPool is Test {
    PredyPool predyPool;

    MockERC20 currency0;
    MockERC20 currency1;

    IUniswapV3Pool internal uniswapPool;

    uint128 internal constant RISK_RATIO = 109544511;
    uint128 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 2000;

    address uniswapFactory;

    PredyPoolQuoter _predyPoolQuoter;

    UniswapSettlement uniswapSettlement;
    DebugSettlement2 debugSettlement;

    function setUp() public virtual {
        currency0 = new MockERC20("currency0", "currency0", 18);
        currency1 = new MockERC20("currency1", "currency1", 18);

        if (address(currency0) < address(currency1)) {
            (currency0, currency1) = (currency1, currency0);
        }

        currency0.mint(address(this), 2 ** 254);
        currency1.mint(address(this), 2 ** 254);

        uniswapFactory =
            deployCode("../node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol:UniswapV3Factory");

        uniswapPool =
            IUniswapV3Pool(IUniswapV3Factory(uniswapFactory).createPool(address(currency0), address(currency1), 500));

        uniswapPool.initialize(2 ** 96);

        IUniswapV3PoolActions(address(uniswapPool)).increaseObservationCardinalityNext(180);

        currency0.approve(address(uniswapPool), type(uint256).max);
        currency1.approve(address(uniswapPool), type(uint256).max);

        uniswapPool.mint(address(this), -4000, 4000, 1e18, bytes(""));

        predyPool = new PredyPool();
        predyPool.initialize(uniswapFactory);

        currency0.approve(address(predyPool), type(uint256).max);
        currency1.approve(address(predyPool), type(uint256).max);

        _movePrice(true, 100);
        vm.warp(block.timestamp + 30 minutes);
        _movePrice(false, 100);

        _predyPoolQuoter = new PredyPoolQuoter(predyPool);

        address swapRouter = deployCode(
            "../node_modules/@uniswap/v3-periphery/artifacts/contracts/SwapRouter.sol:SwapRouter",
            abi.encode(uniswapFactory, address(currency0))
        );
        address quoterV2 = deployCode(
            "../node_modules/@uniswap/v3-periphery/artifacts/contracts/lens/QuoterV2.sol:QuoterV2",
            abi.encode(uniswapFactory, address(currency0))
        );

        uniswapSettlement = new UniswapSettlement(swapRouter, quoterV2);

        debugSettlement = new DebugSettlement2();
        currency0.mint(address(debugSettlement), 2 ** 254);
        currency1.mint(address(debugSettlement), 2 ** 254);
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata) external {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(IUniswapV3Pool(msg.sender).token0(), msg.sender, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(IUniswapV3Pool(msg.sender).token1(), msg.sender, amount1);
        }
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) {
            TransferHelper.safeTransfer(IUniswapV3Pool(msg.sender).token0(), msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            TransferHelper.safeTransfer(IUniswapV3Pool(msg.sender).token1(), msg.sender, uint256(amount1Delta));
        }
    }

    function registerPair(address marginId, address priceFeed) public returns (uint256) {
        return registerPair(marginId, priceFeed, false);
    }

    function registerPair(address marginId, address priceFeed, bool isWhitelistEnabled) internal returns (uint256) {
        InterestRateModel.IRMParams memory irmParams = InterestRateModel.IRMParams(1e16, 9 * 1e17, 5 * 1e17, 1e18);

        return predyPool.registerPair(
            AddPairLogic.AddPairParams(
                marginId,
                address(this),
                address(uniswapPool),
                // set up oracle
                priceFeed,
                isWhitelistEnabled,
                0,
                Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 1005000, 1050000),
                irmParams,
                irmParams
            )
        );
    }

    function _movePrice(bool _isUp, int256 amount) internal {
        if (_isUp) {
            uniswapPool.swap(address(this), true, -amount, TickMath.MIN_SQRT_RATIO + 1, "");
        } else {
            uniswapPool.swap(address(this), false, amount, TickMath.MAX_SQRT_RATIO - 1, "");
        }
    }

    function _getTradeAfterParams(uint256 updateMarginAmount)
        internal
        view
        returns (TestTradeMarket.TradeAfterParams memory)
    {
        return TestTradeMarket.TradeAfterParams(address(this), address(currency1), updateMarginAmount);
    }

    function _getSettlementData(uint256 price) internal pure returns (IFillerMarket.SettlementParams memory) {
        return IFillerMarket.SettlementParams(address(0), bytes(""), 0, price, 0);
    }

    function _getDebugSettlementData(uint256 price, uint256 maxQuoteAmount)
        internal
        view
        returns (IFillerMarket.SettlementParams memory)
    {
        return IFillerMarket.SettlementParams(address(debugSettlement), abi.encode(price), maxQuoteAmount, price, 0);
    }

    function _getUniSettlementData(uint256 maxQuoteAmount)
        internal
        view
        returns (IFillerMarket.SettlementParams memory)
    {
        return _getUniSettlementData(maxQuoteAmount, 0, 0);
    }

    function _getUniSettlementData(uint256 maxQuoteAmount, uint256 price, int256 fee)
        internal
        view
        returns (IFillerMarket.SettlementParams memory)
    {
        bytes memory path = abi.encodePacked(address(currency0), uint24(500), address(currency1));

        return IFillerMarket.SettlementParams(address(uniswapSettlement), path, maxQuoteAmount, price, fee);
    }

    // settlement data v3

    function _getSettlementDataV3(uint256 price) internal pure returns (IFillerMarket.SettlementParamsV3 memory) {
        return IFillerMarket.SettlementParamsV3(address(0), bytes(""), 0, 0, price, 0, 0);
    }

    function _getDebugSettlementDataV3(uint256 price, uint256 maxQuoteAmountPrice)
        internal
        view
        returns (IFillerMarket.SettlementParamsV3 memory)
    {
        return IFillerMarket.SettlementParamsV3(
            address(debugSettlement), abi.encode(price), maxQuoteAmountPrice, 0, price, 0, 0
        );
    }

    function _getUniSettlementDataV3(uint256 maxQuoteAmountPrice)
        internal
        view
        returns (IFillerMarket.SettlementParamsV3 memory)
    {
        return _getUniSettlementDataV3(maxQuoteAmountPrice, 0, 0);
    }

    function _getUniSettlementDataV3(uint256 maxQuoteAmountPrice, uint256 price, uint256 feePrice)
        internal
        view
        returns (IFillerMarket.SettlementParamsV3 memory)
    {
        bytes memory path = abi.encodePacked(address(currency0), uint24(500), address(currency1));

        return IFillerMarket.SettlementParamsV3(
            address(uniswapSettlement), path, maxQuoteAmountPrice, 0, price, feePrice, 0
        );
    }
}
