// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../../src/libraries/InterestRateModel.sol";
import "../../mocks/MockERC20.sol";
import "../../utils/PairStatusUtils.sol";

contract TestPositionCalculator is Test, PairStatusUtils {
    MockERC20 internal usdc;
    MockERC20 internal weth;

    address internal token0;
    address internal token1;

    IUniswapV3Pool internal uniswapPool;
    InterestRateModel.IRMParams internal irmParams;

    uint256 internal constant PAIR_GROUP_ID = 1;

    function setUp() public virtual {
        irmParams = InterestRateModel.IRMParams(1e16, 9 * 1e17, 5 * 1e17, 1e18);

        // Set up tokens
        usdc = new MockERC20("usdc", "USDC", 6);
        weth = new MockERC20("weth", "WETH", 18);

        usdc.mint(address(this), type(uint128).max);
        weth.mint(address(this), type(uint128).max);

        // Set up Uniswap pool
        address factory =
            deployCode("../node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol:UniswapV3Factory");

        uniswapPool = IUniswapV3Pool(IUniswapV3Factory(factory).createPool(address(weth), address(usdc), 500));

        uniswapPool.initialize(2 ** 96);

        IUniswapV3PoolActions(address(uniswapPool)).increaseObservationCardinalityNext(180);

        usdc.approve(address(uniswapPool), type(uint256).max);
        weth.approve(address(uniswapPool), type(uint256).max);

        uniswapPool.mint(address(this), -2000, 2000, 1e18, bytes(""));

        vm.warp(block.timestamp + 1 minutes);
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
}
