// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {SpotOrder} from "../../../src/markets/spot/SpotOrder.sol";
import {SpotMarketOrder, SpotLimitOrder} from "../../../src/markets/spot/SpotMarketL2.sol";
import {SpotMarket} from "../../../src/markets/spot/SpotMarket.sol";

contract TestSpotExecuteL2Order is TestSpotMarket {
    uint256 private fromPrivateKey1;
    address private from1;

    function setUp() public override {
        TestSpotMarket.setUp();

        fromPrivateKey1 = 0x12341234;
        from1 = vm.addr(fromPrivateKey1);

        currency0.mint(from1, type(uint128).max);
        currency1.mint(from1, type(uint128).max);

        vm.prank(from1);
        currency0.approve(address(permit2), type(uint256).max);

        vm.prank(from1);
        currency1.approve(address(permit2), type(uint256).max);

        currency0.mint(address(settlement), type(uint128).max);
        currency1.mint(address(settlement), type(uint128).max);
    }

    function _checkBalances() internal {
        assertEq(currency0.balanceOf(address(spotMarket)), 0);
        assertEq(currency1.balanceOf(address(spotMarket)), 0);
    }

    function invariantSpotMarket() external {
        _checkBalances();
    }

    function testExecuteMarketOrderSucceeds() public {
        SpotOrder memory order = SpotOrder(
            OrderInfo(address(spotMarket), from1, 0, block.timestamp + 100),
            address(currency1),
            address(currency0),
            1000,
            1100,
            0,
            abi.encode(SpotMarket.AuctionParams(1000, 1100, block.timestamp - 1 minutes, block.timestamp + 4 minutes))
        );

        SpotMarketOrder memory orderL2 = SpotMarketOrder(
            order.info.trader,
            order.info.nonce,
            order.info.deadline,
            order.quoteToken,
            order.baseToken,
            order.baseTokenAmount,
            order.quoteTokenAmount,
            abi.encode(SpotMarket.AuctionParams(1000, 1100, block.timestamp - 1 minutes, block.timestamp + 4 minutes))
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        int256 quoteTokenAmount =
            spotMarket.executeMarketOrder(orderL2, signedOrder.sig, _getSpotSettlementParams(1000, 1000));

        assertEq(quoteTokenAmount, -1000);

        _checkBalances();
    }

    function testExecuteLimitOrderSucceeds() public {
        SpotOrder memory order = SpotOrder(
            OrderInfo(address(spotMarket), from1, 0, block.timestamp + 100),
            address(currency1),
            address(currency0),
            1000,
            1100,
            1100,
            bytes("")
        );

        SpotLimitOrder memory orderL2 = SpotLimitOrder(
            order.info.trader,
            order.info.nonce,
            order.info.deadline,
            order.quoteToken,
            order.baseToken,
            order.baseTokenAmount,
            order.quoteTokenAmount,
            1100
        );

        IFillerMarket.SignedOrder memory signedOrder = _createSignedOrder(order, fromPrivateKey1);

        int256 quoteTokenAmount =
            spotMarket.executeLimitOrder(orderL2, signedOrder.sig, _getSpotSettlementParams(1000, 1000));

        assertEq(quoteTokenAmount, -1000);

        _checkBalances();
    }
}
