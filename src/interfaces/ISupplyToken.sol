// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.7.0;

interface ISupplyToken {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
