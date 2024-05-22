// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ArrayLib} from "../../../src/markets/gamma/ArrayLib.sol";

contract TestArrayLib is Test {
    uint256[] private _items;

    function testAddItem() public {
        ArrayLib.addItem(_items, 5);

        assertEq(_items.length, 1);
        assertEq(_items[0], 5);
    }

    function testRemoveItem() public {
        ArrayLib.addItem(_items, 5);
        ArrayLib.removeItem(_items, 5);

        assertEq(_items.length, 0);
    }
}
