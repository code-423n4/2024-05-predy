// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";
import {AggregatorV3Interface} from "./vendors/AggregatorV3Interface.sol";
import {IPyth} from "./vendors/IPyth.sol";
import {Constants} from "./libraries/Constants.sol";

contract PriceFeedFactory {
    address private immutable _pyth;

    event PriceFeedCreated(address quotePrice, bytes32 priceId, uint256 decimalsDiff, address priceFeed);

    constructor(address pyth) {
        _pyth = pyth;
    }

    function createPriceFeed(address quotePrice, bytes32 priceId, uint256 decimalsDiff) external returns (address) {
        PriceFeed priceFeed = new PriceFeed(quotePrice, _pyth, priceId, decimalsDiff);

        emit PriceFeedCreated(quotePrice, priceId, decimalsDiff, address(priceFeed));

        return address(priceFeed);
    }
}

/// @title PriceFeed
/// @notice The contract provides the square root price of the base token in terms of the quote token
contract PriceFeed {
    address private immutable _quotePriceFeed;
    address private immutable _pyth;
    uint256 private immutable _decimalsDiff;
    bytes32 private immutable _priceId;

    uint256 private constant VALID_TIME_PERIOD = 5 * 60;

    constructor(address quotePrice, address pyth, bytes32 priceId, uint256 decimalsDiff) {
        _quotePriceFeed = quotePrice;
        _pyth = pyth;
        _priceId = priceId;
        _decimalsDiff = decimalsDiff;
    }

    /// @notice This function returns the square root of the baseToken price quoted in quoteToken.
    function getSqrtPrice() external view returns (uint256 sqrtPrice) {
        (, int256 quoteAnswer,,,) = AggregatorV3Interface(_quotePriceFeed).latestRoundData();

        IPyth.Price memory basePrice = IPyth(_pyth).getPriceNoOlderThan(_priceId, VALID_TIME_PERIOD);

        require(basePrice.expo == -8, "INVALID_EXP");

        require(quoteAnswer > 0 && basePrice.price > 0);

        uint256 price = uint256(int256(basePrice.price)) * Constants.Q96 / uint256(quoteAnswer);
        price = price * Constants.Q96 / _decimalsDiff;

        sqrtPrice = FixedPointMathLib.sqrt(price);
    }
}
