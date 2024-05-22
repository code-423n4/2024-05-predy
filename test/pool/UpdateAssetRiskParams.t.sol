// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TestPool} from "./Setup.t.sol";
import {IPredyPool} from "../../src/interfaces/IPredyPool.sol";
import {Perp} from "../../src/libraries/Perp.sol";
import {DataType} from "../../src/libraries/DataType.sol";
import {InterestRateModel} from "../../src/libraries/InterestRateModel.sol";
import {AddPairLogic} from "../../src/libraries/logic/AddPairLogic.sol";

contract TestPoolUpdateAssetRiskParams is TestPool {
    address private poolOwner;
    address private notPoolOwner;
    uint256 private pairId;

    function setUp() public override {
        TestPool.setUp();

        poolOwner = vm.addr(0x0001);
        notPoolOwner = vm.addr(0x0002);

        InterestRateModel.IRMParams memory irmParams = InterestRateModel.IRMParams(1e16, 9 * 1e17, 5 * 1e17, 1e18);

        pairId = predyPool.registerPair(
            AddPairLogic.AddPairParams(
                address(currency0),
                poolOwner,
                address(uniswapPool),
                address(0),
                false,
                0,
                Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 1005000, 1050000),
                irmParams,
                irmParams
            )
        );
    }

    function testUpdateAssetRiskParams() public {
        vm.prank(poolOwner);
        predyPool.updateAssetRiskParams(
            pairId, Perp.AssetRiskParams(110020500, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 1005000, 1050000)
        );

        DataType.PairStatus memory pairStatus = predyPool.getPairStatus(pairId);

        assertEq(pairStatus.riskParams.riskRatio, 110020500);
    }

    function testCannotUpdateAssetRiskParams() public {
        vm.startPrank(notPoolOwner);

        vm.expectRevert(IPredyPool.CallerIsNotPoolCreator.selector);
        predyPool.updateAssetRiskParams(
            pairId, Perp.AssetRiskParams(RISK_RATIO, BASE_MIN_COLLATERAL_WITH_DEBT, 1000, 500, 1005000, 1050000)
        );

        vm.stopPrank();
    }
}
