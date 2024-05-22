// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Setup.t.sol";

contract TestPerpUtils is TestPerp {
    Perp.SqrtPerpAssetStatus sqrtStatus;

    function setUp() public override {
        TestPerp.setUp();

        sqrtStatus = Perp.createAssetStatus(address(0), 0, 0);
    }

    function testGetAvailableSqrtAmountWithNoUsageIfWithdraw() public {
        sqrtStatus.totalAmount = 1000000;
        sqrtStatus.borrowedAmount = 0;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, true);

        assertEq(availableAmount, 1000000);
    }

    function testGetAvailableSqrtAmountWithNoUsageIfBorrow() public {
        sqrtStatus.totalAmount = 1000000;
        sqrtStatus.borrowedAmount = 0;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, false);

        assertEq(availableAmount, 980000);
    }

    function testGetAvailableSqrtAmountHalfUsageIfWithdraw() public {
        sqrtStatus.totalAmount = 1000000;
        sqrtStatus.borrowedAmount = 500000;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, true);

        assertEq(availableAmount, 480000);
    }

    function testGetAvailableSqrtAmountHalfUsageIfBorrow() public {
        sqrtStatus.totalAmount = 1000000;
        sqrtStatus.borrowedAmount = 500000;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, false);

        assertEq(availableAmount, 480000);
    }

    function testGetAvailableSqrtAmountFullUsage() public {
        sqrtStatus.totalAmount = 1000000;
        sqrtStatus.borrowedAmount = 1000000;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, false);

        assertEq(availableAmount, 0);
    }

    function testGetAvailableSqrtAmountWithSmallIfBorrow() public {
        sqrtStatus.totalAmount = 100;
        sqrtStatus.borrowedAmount = 0;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, false);

        assertEq(availableAmount, 0);
    }

    function testGetAvailableSqrtAmountWithSmallIfWithdraw() public {
        sqrtStatus.totalAmount = 200;
        sqrtStatus.borrowedAmount = 100;

        uint256 availableAmount = Perp.getAvailableSqrtAmount(sqrtStatus, true);

        assertEq(availableAmount, 0);
    }
}
