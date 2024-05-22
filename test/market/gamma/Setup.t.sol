// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import "../../pool/Setup.t.sol";
import "../../../src/interfaces/ISettlement.sol";
import {IFillerMarket} from "../../../src/interfaces/IFillerMarket.sol";
import {GammaTradeMarketWrapper} from "../../../src/markets/gamma/GammaTradeMarketWrapper.sol";
import {GammaTradeMarket} from "../../../src/markets/gamma/GammaTradeMarket.sol";
import "../../../src/markets/gamma/GammaOrder.sol";
import "../../../src/libraries/Constants.sol";
import {SigUtils} from "../../utils/SigUtils.sol";
import {OrderValidatorUtils} from "../../utils/OrderValidatorUtils.sol";

contract TestGammaMarket is TestPool, SigUtils, OrderValidatorUtils {
    using GammaOrderLib for GammaOrder;

    GammaTradeMarketWrapper gammaTradeMarket;
    IPermit2 permit2;
    bytes32 DOMAIN_SEPARATOR;

    function setUp() public virtual override(TestPool) {
        TestPool.setUp();

        permit2 = IPermit2(deployCode("../test-artifacts/Permit2.sol:Permit2"));

        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        gammaTradeMarket = new GammaTradeMarketWrapper();

        gammaTradeMarket.initialize(predyPool, address(permit2), address(this), address(_predyPoolQuoter));

        gammaTradeMarket.updateWhitelistSettlement(address(uniswapSettlement), true);

        currency0.approve(address(permit2), type(uint256).max);
        currency1.approve(address(permit2), type(uint256).max);

        currency0.approve(address(gammaTradeMarket), type(uint256).max);
        currency1.approve(address(gammaTradeMarket), type(uint256).max);
    }

    function _sign(GammaOrder memory marketOrder, uint256 fromPrivateKey) internal view returns (bytes memory) {
        bytes32 witness = marketOrder.hash();

        return getPermitSignature(
            fromPrivateKey,
            _toPermit(marketOrder),
            address(gammaTradeMarket),
            GammaOrderLib.PERMIT2_ORDER_TYPE,
            witness,
            DOMAIN_SEPARATOR
        );
    }

    function _createOrder(
        address trader,
        uint256 nonce,
        uint256 deadline,
        uint64 pairId,
        uint256 positionId,
        int256 quantity,
        int256 quantitySqrt,
        int256 marginAmount,
        uint256 baseSqrtPrice
    ) internal view returns (GammaOrder memory order) {
        order = GammaOrder(
            OrderInfo(address(gammaTradeMarket), trader, nonce, deadline),
            pairId,
            positionId,
            address(currency1),
            quantity,
            quantitySqrt,
            marginAmount,
            baseSqrtPrice,
            1e6 + 5000, // 0.5%
            2,
            GammaModifyInfo(
                false,
                // auto close
                0,
                0,
                0,
                0,
                // auto hedge
                0,
                0,
                // slippage tolerance
                0,
                0,
                0,
                0
            )
        );
    }
}
