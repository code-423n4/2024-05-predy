// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ISettlement} from "../../src/interfaces/ISettlement.sol";
import {Constants} from "../../src/libraries/Constants.sol";

contract DebugSettlement2 is ISettlement {
    using SafeTransferLib for ERC20;

    function swapExactIn(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountIn,
        uint256,
        address recipient
    ) external override returns (uint256 amountOut) {
        uint256 price = abi.decode(data, (uint256));

        amountOut = amountIn * price / Constants.Q96;

        ERC20(baseToken).safeTransferFrom(msg.sender, address(this), amountIn);
        ERC20(quoteToken).safeTransfer(recipient, amountOut);
    }

    function swapExactOut(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountOut,
        uint256 maxAmountIn,
        address recipient
    ) external override returns (uint256 amountIn) {
        uint256 price = abi.decode(data, (uint256));

        amountIn = amountOut * price / Constants.Q96;

        ERC20(baseToken).safeTransfer(recipient, amountOut);

        ERC20(quoteToken).safeTransferFrom(msg.sender, address(this), amountIn);
    }

    function quoteSwapExactIn(bytes memory, uint256) external override returns (uint256) {
        return 0;
    }

    function quoteSwapExactOut(bytes memory, uint256) external override returns (uint256) {
        return 0;
    }
}
