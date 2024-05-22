// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice Mock of price feed contract
 */
contract MockPriceFeed {
    uint256 sqrtPrice;

    function setSqrtPrice(uint256 newSqrtPrice) external {
        sqrtPrice = newSqrtPrice;
    }

    function getSqrtPrice() external view returns (uint256) {
        return sqrtPrice;
    }
}
