// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @notice helpers for handling dutch auction
library DecayLib {
    error EndTimeBeforeStartTime();

    function decay(uint256 startPrice, uint256 endPrice, uint256 decayStartTime, uint256 decayEndTime)
        internal
        view
        returns (uint256 decayedPrice)
    {
        decayedPrice = decay2(startPrice, endPrice, decayStartTime, decayEndTime, block.timestamp);
    }

    function decay2(uint256 startPrice, uint256 endPrice, uint256 decayStartTime, uint256 decayEndTime, uint256 value)
        internal
        pure
        returns (uint256 decayedPrice)
    {
        if (decayEndTime < decayStartTime) {
            revert EndTimeBeforeStartTime();
        } else if (decayEndTime <= value) {
            decayedPrice = endPrice;
        } else if (decayStartTime >= value) {
            decayedPrice = startPrice;
        } else {
            uint256 elapsed = value - decayStartTime;
            uint256 duration = decayEndTime - decayStartTime;

            if (endPrice < startPrice) {
                decayedPrice = startPrice - (startPrice - endPrice) * elapsed / duration;
            } else {
                decayedPrice = startPrice + (endPrice - startPrice) * elapsed / duration;
            }
        }
    }
}
