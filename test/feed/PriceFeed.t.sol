// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/PriceFeed.sol";
import {IPyth} from "../../src/vendors/IPyth.sol";

contract MockPriceFeed {
    int256 latestAnswer;

    function setAnswer(int256 answer) external {
        latestAnswer = answer;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 0;
        answer = latestAnswer;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }
}

contract MockPyth {
    int64 latestAnswer;

    function setAnswer(int64 answer) external {
        latestAnswer = answer;
    }

    function getPriceNoOlderThan(bytes32, uint256) external view returns (IPyth.Price memory price) {
        price.price = latestAnswer;
        price.expo = -8;
    }
}

contract PriceFeedTest is Test {
    PriceFeed priceFeed;

    MockPriceFeed mockQuotePriceFeed;
    MockPyth mockBasePriceFeed;

    function setUp() public {
        mockQuotePriceFeed = new MockPriceFeed();
        mockBasePriceFeed = new MockPyth();

        priceFeed = new PriceFeed(address(mockQuotePriceFeed), address(mockBasePriceFeed), bytes32(0), 1e12);
    }

    function testGetSqrtPrice() public {
        mockBasePriceFeed.setAnswer(1620 * 1e8);
        mockQuotePriceFeed.setAnswer(1e8);

        assertEq(priceFeed.getSqrtPrice(), 3188872028057322785329830);
    }

    function testGetSqrtPriceFuzz(uint256 a, uint256 b) public {
        a = bound(a, 1, 1e14);
        b = bound(a, 1, 2 * 1e8);

        mockBasePriceFeed.setAnswer(int64(uint64(a)));
        mockQuotePriceFeed.setAnswer(int64(uint64(b)));

        assertGt(priceFeed.getSqrtPrice(), 0);
    }
}
