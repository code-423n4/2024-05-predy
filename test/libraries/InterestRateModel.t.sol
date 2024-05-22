// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/InterestRateModel.sol";

contract InterestRateModelTest is Test {
    InterestRateModel.IRMParams irmParams;

    function setUp() public {
        irmParams = InterestRateModel.IRMParams(1e16, 50 * 1e16, 1e17, 1e18);
    }

    function testCalculateInterestRateFuzz(uint256 _utilizationRatio) public {
        uint256 utilizationRatio = bound(_utilizationRatio, 0, 1e18);

        assertGe(InterestRateModel.calculateInterestRate(irmParams, utilizationRatio), 1e16);
        assertLt(InterestRateModel.calculateInterestRate(irmParams, utilizationRatio), 60 * 1e16);
    }

    function testCalculateInterestRate() public {
        assertEq(InterestRateModel.calculateInterestRate(irmParams, 0), 1e16);
        assertEq(InterestRateModel.calculateInterestRate(irmParams, 1e16), 11000000000000000);
        assertEq(InterestRateModel.calculateInterestRate(irmParams, 50 * 1e16), 60000000000000000);
        assertEq(InterestRateModel.calculateInterestRate(irmParams, 99 * 1e16), 550000000000000000);
        assertEq(InterestRateModel.calculateInterestRate(irmParams, 1e18), 560000000000000000);
    }
}
