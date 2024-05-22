// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ISettlement} from "../../src/interfaces/ISettlement.sol";

contract DebugSettlement is ISettlement {
    using SafeTransferLib for ERC20;

    struct RouteParams {
        uint256 quoteAmount;
        uint256 baseAmount;
    }

    function swapExactIn(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountIn,
        uint256,
        address recipient
    ) external override returns (uint256 amountOut) {
        RouteParams memory params = abi.decode(data, (RouteParams));

        ERC20(baseToken).safeTransferFrom(msg.sender, address(this), amountIn);
        ERC20(quoteToken).safeTransfer(recipient, params.quoteAmount);

        amountOut = params.quoteAmount;
    }

    function swapExactOut(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256,
        uint256 maxAmountIn,
        address recipient
    ) external override returns (uint256 amountIn) {
        RouteParams memory params = abi.decode(data, (RouteParams));

        ERC20(quoteToken).safeTransferFrom(msg.sender, address(this), maxAmountIn);
        ERC20(baseToken).safeTransfer(recipient, params.baseAmount);

        amountIn = maxAmountIn;
    }

    function quoteSwapExactIn(bytes memory, uint256) external pure override returns (uint256) {
        return 0;
    }

    function quoteSwapExactOut(bytes memory, uint256) external pure override returns (uint256) {
        return 0;
    }
}
