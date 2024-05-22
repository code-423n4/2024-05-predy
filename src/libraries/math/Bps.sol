// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library Bps {
    uint32 public constant ONE = 1e6;

    function upper(uint256 price, uint256 bps) internal pure returns (uint256) {
        return price * bps / ONE;
    }

    function lower(uint256 price, uint256 bps) internal pure returns (uint256) {
        return price * ONE / bps;
    }
}
