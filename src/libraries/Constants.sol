// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library Constants {
    uint256 internal constant ONE = 1e18;

    uint256 internal constant MAX_VAULTS = 18446744073709551616;
    uint256 internal constant MAX_PAIRS = 18446744073709551616;

    // Margin option
    int256 internal constant MIN_MARGIN_AMOUNT = 1e6;

    uint256 internal constant MIN_LIQUIDITY = 100;

    uint256 internal constant MIN_SQRT_PRICE = 79228162514264337593;
    uint256 internal constant MAX_SQRT_PRICE = 79228162514264337593543950336000000000;

    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    // 0.1%
    uint256 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 1000;
    // 2.5% scaled by 1e6
    uint256 internal constant BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE = 12422;
    // 5.0% scaled by 1e6
    uint256 internal constant MAX_LIQ_SLIPPAGE_SQRT_TOLERANCE = 24710;
    // 2.5% scaled by 1e6
    uint256 internal constant SLIPPAGE_SQRT_TOLERANCE = 12422;

    // 10%
    uint256 internal constant SQUART_KINK_UR = 10 * 1e16;
}
