// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

/// @dev dammy uniswap pool not registered in factory
contract MockUniswapPool {
    address public token0;
    address public token1;
    uint24 public fee;
}

contract TestRegisterPair is TestPool {
    InterestRateModel.IRMParams irmParams;

    function setUp() public override {
        TestPool.setUp();

        irmParams = InterestRateModel.IRMParams(1e16, 9 * 1e17, 5 * 1e17, 1e18);
    }

    // register pool succeeds
    function testRegisterSucceeds() public {
        predyPool.registerPair(
            AddPairLogic.AddPairParams(
                address(currency1),
                address(this),
                address(uniswapPool),
                address(0),
                false,
                0,
                Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 10050, 10500),
                irmParams,
                irmParams
            )
        );
    }

    // register fails if uniswap pool is not registered in factory
    function testCannotRegister() public {
        address uniswapPool = address(new MockUniswapPool());

        vm.expectRevert(AddPairLogic.InvalidUniswapPool.selector);
        predyPool.registerPair(
            AddPairLogic.AddPairParams(
                address(currency1),
                address(this),
                uniswapPool,
                address(0),
                false,
                0,
                Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 10050, 10500),
                irmParams,
                irmParams
            )
        );
    }

    function testCannotRegisterIfNotOperator() public {
        vm.startPrank(address(1));

        vm.expectRevert(IPredyPool.CallerIsNotOperator.selector);
        predyPool.registerPair(
            AddPairLogic.AddPairParams(
                address(currency1),
                address(this),
                address(uniswapPool),
                address(0),
                false,
                0,
                Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 10050, 10500),
                irmParams,
                irmParams
            )
        );

        vm.stopPrank();
    }
}
