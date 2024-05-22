// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../../src/libraries/Constants.sol";

contract TestExecLiquidationCall is TestGammaMarket {
    bytes normalSwapRoute;
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;

    function setUp() public override {
        TestGammaMarket.setUp();

        registerPair(address(currency1), address(0));
        gammaTradeMarket.updateQuoteTokenMap(1);

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

        normalSwapRoute = abi.encodePacked(address(currency0), uint24(500), address(currency1));

        fromPrivateKey1 = 0x12341234;
        from1 = vm.addr(fromPrivateKey1);
        fromPrivateKey2 = 0x1235678;
        from2 = vm.addr(fromPrivateKey2);

        currency1.mint(from1, type(uint128).max);
        currency1.mint(from2, type(uint128).max);

        vm.prank(from1);
        currency1.approve(address(permit2), type(uint256).max);

        vm.prank(from2);
        currency1.approve(address(permit2), type(uint256).max);
    }

    // liquidate succeeds if the vault is danger
    function testLiquidateSucceedsIfVaultIsDanger() public {
        GammaOrder memory order = _createOrder(from1, 0, block.timestamp + 100, 1, 0, -4 * 1e8, 0, 1e8, Constants.Q96);

        bytes memory signature = _sign(order, fromPrivateKey1);

        gammaTradeMarket.executeTrade(order, signature, _getSettlementDataV3(Constants.Q96));

        _movePrice(true, 6 * 1e16);

        vm.warp(block.timestamp + 30 minutes);

        uint256 beforeMargin = currency1.balanceOf(from1);
        gammaTradeMarket.execLiquidationCall(1, 1e18, _getSettlementDataV3(Constants.Q96));
        uint256 afterMargin = currency1.balanceOf(from1);

        assertGt(afterMargin - beforeMargin, 0);

        GammaTradeMarket.UserPositionResult[] memory results = gammaTradeMarket.getUserPositions(from1);

        assertEq(results.length, 0);
    }
}
