// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library ArrayLib {
    function addItem(uint256[] storage items, uint256 item) internal {
        items.push(item);
    }

    function removeItem(uint256[] storage items, uint256 item) internal {
        uint256 index = getItemIndex(items, item);

        removeItemByIndex(items, index);
    }

    function removeItemByIndex(uint256[] storage items, uint256 index) internal {
        items[index] = items[items.length - 1];
        items.pop();
    }

    function getItemIndex(uint256[] memory items, uint256 item) internal pure returns (uint256) {
        uint256 index = type(uint256).max;

        for (uint256 i = 0; i < items.length; i++) {
            if (items[i] == item) {
                index = i;
                break;
            }
        }

        return index;
    }
}
