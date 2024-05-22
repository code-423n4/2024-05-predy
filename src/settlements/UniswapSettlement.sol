// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import "../interfaces/ISettlement.sol";

contract UniswapSettlement is ISettlement {
    using SafeTransferLib for ERC20;

    ISwapRouter private immutable _swapRouter;
    IQuoterV2 private immutable _quoterV2;

    constructor(address swapRouterAddress, address quoterAddress) {
        _swapRouter = ISwapRouter(swapRouterAddress);

        _quoterV2 = IQuoterV2(quoterAddress);
    }

    function swapExactIn(
        address,
        address baseToken,
        bytes memory data,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external override returns (uint256 amountOut) {
        ERC20(baseToken).safeTransferFrom(msg.sender, address(this), amountIn);
        ERC20(baseToken).approve(address(_swapRouter), amountIn);

        amountOut = _swapRouter.exactInput(
            ISwapRouter.ExactInputParams(data, recipient, block.timestamp, amountIn, amountOutMinimum)
        );
    }

    function swapExactOut(
        address quoteToken,
        address,
        bytes memory data,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external override returns (uint256 amountIn) {
        ERC20(quoteToken).safeTransferFrom(msg.sender, address(this), amountInMaximum);
        ERC20(quoteToken).approve(address(_swapRouter), amountInMaximum);

        amountIn = _swapRouter.exactOutput(
            ISwapRouter.ExactOutputParams(data, recipient, block.timestamp, amountOut, amountInMaximum)
        );

        if (amountInMaximum > amountIn) {
            ERC20(quoteToken).safeTransfer(msg.sender, amountInMaximum - amountIn);
        }
    }

    function quoteSwapExactIn(bytes memory data, uint256 amountIn) external override returns (uint256 amountOut) {
        (amountOut,,,) = _quoterV2.quoteExactInput(data, amountIn);
    }

    function quoteSwapExactOut(bytes memory data, uint256 amountOut) external override returns (uint256 amountIn) {
        (amountIn,,,) = _quoterV2.quoteExactOutput(data, amountOut);
    }
}
