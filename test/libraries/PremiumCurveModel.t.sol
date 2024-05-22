// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/PremiumCurveModel.sol";

contract PremiumCurveModelTest is Test {
    function testCalculatePremiumCurveFuzz(uint256 _utilizationRatio) public {
        uint256 utilizationRatio = bound(_utilizationRatio, 0, 1e18);

        assertGe(PremiumCurveModel.calculatePremiumCurve(utilizationRatio), 0);
        assertLe(PremiumCurveModel.calculatePremiumCurve(utilizationRatio), 60 * 1e16);
    }

    function testCalculatePremiumCurve() public {
        assertEq(PremiumCurveModel.calculatePremiumCurve(0), 0);
        assertEq(PremiumCurveModel.calculatePremiumCurve(25 * 1e16), 36);
        assertEq(PremiumCurveModel.calculatePremiumCurve(40 * 1e16), 144);
        assertEq(PremiumCurveModel.calculatePremiumCurve(50 * 1e16), 256);
        assertEq(PremiumCurveModel.calculatePremiumCurve(1e18), 1296);
    }
}
