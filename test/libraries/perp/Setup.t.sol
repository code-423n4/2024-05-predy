// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../../src/libraries/Perp.sol";
import "../../mocks/MockERC20.sol";
import "../../../src/libraries/InterestRateModel.sol";
import {PairStatusUtils} from "../../utils/PairStatusUtils.sol";

contract TestPerp is Test, PairStatusUtils {
    MockERC20 internal usdc;
    MockERC20 internal weth;
    address internal token0;
    address internal token1;
    IUniswapV3Pool internal uniswapPool;

    DataType.PairStatus internal pairStatus;
    Perp.UserStatus internal userStatus;

    function setUp() public virtual {
        usdc = new MockERC20("usdc", "USDC", 6);
        weth = new MockERC20("weth", "WETH", 18);

        bool isTokenAToken0 = uint160(address(weth)) < uint160(address(usdc));

        if (isTokenAToken0) {
            token0 = address(weth);
            token1 = address(usdc);
        } else {
            token0 = address(usdc);
            token1 = address(weth);
        }

        usdc.mint(address(this), 1e18);
        weth.mint(address(this), 1e18);

        address factory =
            deployCode("../node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol:UniswapV3Factory");

        uniswapPool = IUniswapV3Pool(IUniswapV3Factory(factory).createPool(address(usdc), address(weth), 500));

        uniswapPool.initialize(2 ** 96);

        uniswapPool.mint(address(this), -1000, 1000, 1000000, bytes(""));

        pairStatus = createAssetStatus(1, address(usdc), address(weth), address(uniswapPool));

        userStatus = Perp.createPerpUserStatus(1);

        ScaledAsset.addAsset(pairStatus.basePool.tokenStatus, 1e8);
        ScaledAsset.addAsset(pairStatus.quotePool.tokenStatus, 1e8);
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata) external {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, msg.sender, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) {
            TransferHelper.safeTransfer(token0, msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            TransferHelper.safeTransfer(token1, msg.sender, uint256(amount1Delta));
        }
    }
}
