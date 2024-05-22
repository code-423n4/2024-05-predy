// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract ScaledAssetUpdatePositionTest is TestScaledAsset {
    uint256 constant PAIR_ID = 1;
    bool constant IS_STABLE_FLAG = false;

    function setUp() public override {
        TestScaledAsset.setUp();
    }

    // updatePosition

    // supply
    function testUpdatePositionToSupply() public {
        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 1e16);
        assertEq(assetStatus.totalNormalBorrowed, 0);
        assertEq(userStatus1.positionAmount, 1e16);
    }

    // withdraw
    function testUpdatePositionToWithdraw() public {
        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 0);
        assertEq(assetStatus.totalNormalBorrowed, 0);
        assertEq(userStatus1.positionAmount, 0);
    }

    // withdraw half
    function testUpdatePositionToWithdrawHalf() public {
        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -5 * 1e15, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 5 * 1e15);
        assertEq(assetStatus.totalNormalBorrowed, 0);
        assertEq(userStatus1.positionAmount, 5 * 1e15);
    }

    // withdraw and borrow
    function testUpdatePositionToWithdrawAndBorrow() public {
        ScaledAsset.addAsset(assetStatus, 1e18);

        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -2 * 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 0);
        assertEq(assetStatus.totalNormalBorrowed, 1e16);
        assertEq(userStatus1.positionAmount, -1e16);
    }

    // cannot withdraw if there is no enough asset
    function testCannotWithdraw() public {
        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);

        ScaledAsset.updatePosition(assetStatus, userStatus0, -100, PAIR_ID, IS_STABLE_FLAG);

        vm.expectRevert(bytes("S0"));
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
    }

    // borrow
    function testUpdatePositionToBorrow() public {
        ScaledAsset.addAsset(assetStatus, 1e18);

        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 0);
        assertEq(assetStatus.totalNormalBorrowed, 1e16);
        assertEq(userStatus1.positionAmount, -1e16);
    }

    // cannot borrow if there is no enough asset
    function testCannotBorrow() public {
        vm.expectRevert(bytes("S0"));
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
    }

    // repay
    function testUpdatePositionToRepay() public {
        ScaledAsset.addAsset(assetStatus, 1e18);

        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 0);
        assertEq(assetStatus.totalNormalBorrowed, 0);
        assertEq(userStatus1.positionAmount, 0);
    }

    // repay half
    function testUpdatePositionToRepayHalf() public {
        ScaledAsset.addAsset(assetStatus, 1e18);

        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, 5 * 1e15, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 0);
        assertEq(assetStatus.totalNormalBorrowed, 5 * 1e15);
        assertEq(userStatus1.positionAmount, -5 * 1e15);
    }

    // repay and deposit
    function testUpdatePositionToRepayAndDeposit() public {
        ScaledAsset.addAsset(assetStatus, 1e18);

        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, 2 * 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(assetStatus.totalNormalDeposited, 1e16);
        assertEq(assetStatus.totalNormalBorrowed, 0);
        assertEq(userStatus1.positionAmount, 1e16);
    }

    // check last fee growth
    function testUpdatePositionToCheckLastFeeGrowth() public {
        ScaledAsset.addAsset(assetStatus, 1e18);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updateScaler(assetStatus, 1e16, 0);

        ScaledAsset.updatePosition(assetStatus, userStatus2, 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(userStatus2.lastFeeGrowth, 100000000000000);

        ScaledAsset.updatePosition(assetStatus, userStatus2, -2 * 1e16, PAIR_ID, IS_STABLE_FLAG);

        assertEq(userStatus2.lastFeeGrowth, 10000000000000000);
    }

    // settle user fee
    function testSettleUserFee() public {
        ScaledAsset.updatePosition(assetStatus, userStatus2, 1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e15, PAIR_ID, IS_STABLE_FLAG);

        ScaledAsset.updateScaler(assetStatus, 1e16, 0);

        assertEq(userStatus2.lastFeeGrowth, 0);

        int256 interestFee = ScaledAsset.settleUserFee(assetStatus, userStatus2);

        assertEq(interestFee, 10000000000000);
        assertEq(userStatus2.lastFeeGrowth, 1000000000000000);
    }

    // update scaler with reserve factor
    function testUpdateScalerWithReserveFactor() public {
        ScaledAsset.updatePosition(assetStatus, userStatus2, 1e16, PAIR_ID, IS_STABLE_FLAG);
        ScaledAsset.updatePosition(assetStatus, userStatus1, -1e15, PAIR_ID, IS_STABLE_FLAG);

        uint256 reserve = ScaledAsset.updateScaler(assetStatus, 1e16, 10);

        assertEq(reserve, 1000000000000);

        assertEq(userStatus2.lastFeeGrowth, 0);

        int256 interestFee = ScaledAsset.settleUserFee(assetStatus, userStatus2);

        assertEq(interestFee, 9000000000000);
        assertEq(userStatus2.lastFeeGrowth, 900000000000000);
    }
}
