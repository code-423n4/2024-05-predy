// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {ISupplyToken} from "../interfaces/ISupplyToken.sol";

contract SupplyToken is ERC20, ISupplyToken {
    address immutable _controller;

    modifier onlyController() {
        require(_controller == msg.sender, "ST0");
        _;
    }

    constructor(address controller, string memory _name, string memory _symbol, uint8 __decimals)
        ERC20(_name, _symbol, __decimals)
    {
        _controller = controller;
    }

    function mint(address account, uint256 amount) external virtual override onlyController {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual override onlyController {
        _burn(account, amount);
    }
}
