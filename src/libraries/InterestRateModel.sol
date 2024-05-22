// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

/**
 * @title InterestRateModel
 * @notice This library is used to define the interest rate curve, which determines the interest rate based on utilization.
 */
library InterestRateModel {
    struct IRMParams {
        uint256 baseRate;
        uint256 kinkRate;
        uint256 slope1;
        uint256 slope2;
    }

    uint256 private constant _ONE = 1e18;

    function calculateInterestRate(IRMParams memory irmParams, uint256 utilizationRatio)
        internal
        pure
        returns (uint256)
    {
        uint256 ir = irmParams.baseRate;

        if (utilizationRatio <= irmParams.kinkRate) {
            ir += (utilizationRatio * irmParams.slope1) / _ONE;
        } else {
            ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;
            ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;
        }

        return ir;
    }
}
