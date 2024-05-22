// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

interface ISettlement {
    function swapExactIn(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut);

    function swapExactOut(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external returns (uint256 amountIn);

    function quoteSwapExactIn(bytes memory data, uint256 amountIn) external returns (uint256 amountOut);

    function quoteSwapExactOut(bytes memory data, uint256 amountOut) external returns (uint256 amountIn);
}
