// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {IPredyPool} from "../../src/interfaces/IPredyPool.sol";
import {SlippageLib} from "../../src/libraries/SlippageLib.sol";

contract SlippageLibTest is Test {
    function testCheckPriceSignature() public {
        assertEq(
            SlippageLib.SlippageTooLarge.selector,
            bytes32(0xf1dff2ba00000000000000000000000000000000000000000000000000000000)
        );
    }

    function testCheckPrice(uint256 a) public {
        int256 averagePrice = int256(bound(a, 0, 2 ** 160)) - 2 ** 159;

        uint256 sqrtBasePrice = 1000 * (2 ** 48);
        uint256 maxAcceptableSqrtPriceRange = 101488915;
        uint256 slippageTolerance = 1005000;

        IPredyPool.TradeResult memory tradeResult;

        tradeResult.averagePrice = averagePrice;
        tradeResult.sqrtPrice = sqrtBasePrice;

        if (averagePrice == 0) {
            vm.expectRevert(SlippageLib.InvalidAveragePrice.selector);
        } else if (averagePrice < -995000) {
            vm.expectRevert(SlippageLib.SlippageTooLarge.selector);
        } else if (0 < averagePrice && averagePrice < 1005000) {
            vm.expectRevert(SlippageLib.SlippageTooLarge.selector);
        }
        SlippageLib.checkPrice(sqrtBasePrice, tradeResult, slippageTolerance, maxAcceptableSqrtPriceRange);
    }
}
