// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import {SignatureVerification} from "@uniswap/permit2/src/libraries/SignatureVerification.sol";
import {ISettlement} from "../../../src/interfaces/ISettlement.sol";
import {OrderInfo} from "../../../src/libraries/orders/OrderInfoLib.sol";
import {Constants} from "../../../src/libraries/Constants.sol";

contract TestGammaGetUserPositions is TestGammaMarket {
    uint256 fromPrivateKey;
    address from;

    function setUp() public override {
        TestGammaMarket.setUp();

        registerPair(address(currency1), address(0));
        gammaTradeMarket.updateQuoteTokenMap(1);

        predyPool.supply(1, true, 1e10);
        predyPool.supply(1, false, 1e10);

        fromPrivateKey = 0x12341234;
        from = vm.addr(fromPrivateKey);

        currency1.mint(from, type(uint128).max);

        vm.prank(from);
        currency1.approve(address(permit2), type(uint256).max);
    }

    function testGetUserPositions() public {
        GammaOrder memory order =
            _createOrder(from, 0, block.timestamp + 100, 1, 0, -1000, 1000, 2 * 1e6, Constants.Q96);

        gammaTradeMarket.executeTrade(order, _sign(order, fromPrivateKey), _getSettlementDataV3(Constants.Q96));

        GammaTradeMarket.UserPositionResult[] memory results = gammaTradeMarket.getUserPositions(from);

        assertEq(results.length, 1);

        GammaOrder memory order2 = _createOrder(from, 1, block.timestamp + 100, 1, 1, 1000, -1000, 0, Constants.Q96);

        gammaTradeMarket.executeTrade(order2, _sign(order2, fromPrivateKey), _getSettlementDataV3(Constants.Q96));

        GammaTradeMarket.UserPositionResult[] memory results2 = gammaTradeMarket.getUserPositions(from);

        assertEq(results2.length, 0);
    }
}
