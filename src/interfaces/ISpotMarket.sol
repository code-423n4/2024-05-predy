// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IFillerMarket} from "./IFillerMarket.sol";

interface ISpotMarket {
    function quoteSettlement(IFillerMarket.SettlementParams memory settlementParams, int256 baseAmountDelta) external;
}
