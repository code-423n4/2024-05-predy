// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISpotMarket} from "../interfaces/ISpotMarket.sol";
import {SpotOrder} from "../markets/spot/SpotOrder.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {IFillerMarket} from "../interfaces/IFillerMarket.sol";

/**
 * @notice Quoter contract for SpotMarket
 */
contract SpotMarketQuoter {
    ISpotMarket spotMarket;

    constructor(ISpotMarket _spotMarket) {
        spotMarket = _spotMarket;
    }

    function quoteExecuteOrderWithTs(SpotOrder memory order, IFillerMarket.SettlementParams memory settlementParams)
        external
        returns (int256 quoteTokenAmount, uint256 timestamp)
    {
        return (quoteExecuteOrder(order, settlementParams), block.timestamp);
    }

    function quoteExecuteOrder(SpotOrder memory order, IFillerMarket.SettlementParams memory settlementParams)
        public
        returns (int256 quoteTokenAmount)
    {
        int256 baseTokenAmount = order.baseTokenAmount;

        try spotMarket.quoteSettlement(settlementParams, -baseTokenAmount) {}
        catch (bytes memory reason) {
            quoteTokenAmount = _parseRevertReason(reason);
        }
    }

    /// @notice Return the trade result of abi-encoded bytes.
    /// @param reason abi-encoded quoteTokenAmount
    function _parseRevertReason(bytes memory reason) private pure returns (int256) {
        if (reason.length != 32) {
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }

        return abi.decode(reason, (int256));
    }
}
