// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {PerpMarketLib} from "../../../src/markets/perp/PerpMarketLib.sol";

contract TestPerpExecLiquidationCall is TestPerpMarket {
    bytes normalSwapRoute;
    uint256 fromPrivateKey1;
    address from1;
    uint256 fromPrivateKey2;
    address from2;

    function setUp() public override {
        TestPerpMarket.setUp();

        registerPair(address(currency1), address(0));
        perpMarket.updateQuoteTokenMap(1);

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
        PerpOrderV3 memory order = PerpOrderV3(
            OrderInfo(address(perpMarket), from1, 0, block.timestamp + 100),
            1,
            address(currency1),
            "Sell",
            4 * 1e8,
            101000000,
            0,
            0,
            4,
            false,
            false,
            abi.encode(PerpMarketLib.AuctionParams(Constants.Q96 / 2, Constants.Q96 / 2, 0, 0))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        perpMarket.executeOrderV3(signedOrder, _getUniSettlementDataV3(0));

        _movePrice(true, 6 * 1e16);

        vm.warp(block.timestamp + 30 minutes);

        uint256 beforeMargin = currency1.balanceOf(from1);
        perpMarket.execLiquidationCall(1, 1e18, _getUniSettlementDataV3(Constants.Q96 * 12 / 10));
        uint256 afterMargin = currency1.balanceOf(from1);

        assertGt(afterMargin - beforeMargin, 0);
    }

    // liquidate fails if the vault does not exist
    // liquidate fails if the vault is safe

    // liquidate succeeds if the vault is danger
    // liquidate succeeds with insolvent vault (compensated from filler pool)
}
