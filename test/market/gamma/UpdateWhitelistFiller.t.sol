// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract TestGammaMarketUpdateWhitelistFiller is TestGammaMarket {
    function setUp() public override {
        TestGammaMarket.setUp();
    }

    function testUpdateWhitelistFiller() public {
        address newWhitelistFiller = vm.addr(0x1234);

        gammaTradeMarket.updateWhitelistFiller(newWhitelistFiller);

        assertEq(gammaTradeMarket.whitelistFiller(), newWhitelistFiller, "whitelist filler not updated");
    }
}
