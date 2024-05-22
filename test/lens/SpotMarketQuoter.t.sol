// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";
import "../../src/lens/SpotMarketQuoter.sol";
import "../../src/markets/spot/SpotMarket.sol";
import {OrderInfo} from "../../src/libraries/orders/OrderInfoLib.sol";
import "../../src/settlements/UniswapSettlement.sol";

contract TestSpotMarketQuoter is TestLens {
    SpotMarketQuoter _quoter;
    SpotMarket _spotMarket;
    address _from;

    function setUp() public override {
        TestLens.setUp();

        IPermit2 permit2 = IPermit2(deployCode("../test-artifacts/Permit2.sol:Permit2"));

        _spotMarket = new SpotMarket(address(permit2));
        _spotMarket.updateWhitelistSettlement(address(uniswapSettlement), true);

        _quoter = new SpotMarketQuoter(_spotMarket);

        _from = vm.addr(1);
    }

    function testQuoteExecuteOrderSucceedsWithBuying() public {
        SpotOrder memory order = SpotOrder(
            OrderInfo(address(0), _from, 0, block.timestamp + 100),
            address(currency1),
            address(currency0),
            1000,
            1100,
            1012, // limit quote token
            bytes("")
        );

        // with settlement contract
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(0)), -1002);

        // with fee
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(0, 0, 10)), -1012);

        // with direct
        {
            assertEq(
                _quoter.quoteExecuteOrder(
                    order, IFillerMarket.SettlementParams(address(0), bytes(""), 0, Constants.Q96, 0)
                ),
                -1000
            );
        }

        // with price
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(0, Constants.Q96, 0)), -1000);
    }

    function testQuoteExecuteOrderSucceedsWithSelling() public {
        SpotOrder memory order = SpotOrder(
            OrderInfo(address(0), _from, 0, block.timestamp + 100),
            address(currency1),
            address(currency0),
            -1000,
            1100,
            988, // limit quote token
            bytes("")
        );

        // with settlement contract
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(1200)), 998);

        // with fee
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(1200, 0, 10)), 988);

        // with direct
        {
            assertEq(
                _quoter.quoteExecuteOrder(
                    order, IFillerMarket.SettlementParams(address(0), bytes(""), 1200, Constants.Q96, 0)
                ),
                1000
            );
        }

        // with price
        assertEq(_quoter.quoteExecuteOrder(order, _getUniSettlementData(1200, Constants.Q96, 0)), 1000);
    }
}
