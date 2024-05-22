// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import "../../src/types/GlobalData.sol";
import "../../src/interfaces/IPredyPool.sol";
import "../../src/interfaces/IFillerMarket.sol";
import "../../src/base/BaseHookCallback.sol";
import "../../src/base/SettlementCallbackLib.sol";
import "../../src/libraries/logic/TradeLogic.sol";

/**
 * @notice A mock market contract for trade tests
 */
contract TestTradeMarket is BaseHookCallback, IFillerMarket {
    struct TradeAfterParams {
        address trader;
        address quoteTokenAddress;
        uint256 marginAmountUpdate;
    }

    constructor(IPredyPool predyPool) BaseHookCallback(predyPool) {}

    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external onlyPredyPool {
        SettlementCallbackLib.execSettlement(
            _predyPool, quoteToken, baseToken, SettlementCallbackLib.decodeParams(settlementData), baseAmountDelta
        );
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external override(BaseHookCallback) onlyPredyPool {
        TradeAfterParams memory tradeAfterParams = abi.decode(tradeParams.extraData, (TradeAfterParams));

        if (tradeResult.minMargin == 0) {
            DataType.Vault memory vault = _predyPool.getVault(tradeParams.vaultId);

            _predyPool.take(true, tradeAfterParams.trader, uint256(vault.margin));
        } else {
            ERC20(tradeAfterParams.quoteTokenAddress).transfer(address(_predyPool), tradeAfterParams.marginAmountUpdate);
        }
    }

    function trade(IPredyPool.TradeParams memory tradeParams, SettlementParams memory settlementData)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        return _predyPool.trade(tradeParams, _getSettlementData(settlementData));
    }

    function reallocate(uint256 pairId, SettlementParams memory settlementData)
        external
        returns (bool relocationOccurred)
    {
        return _predyPool.reallocate(pairId, _getSettlementData(settlementData));
    }

    function execLiquidationCall(uint256 vaultId, uint256 closeRatio, SettlementParams memory settlementData)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        return _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementData(settlementData));
    }

    function _getSettlementData(SettlementParams memory settlementParams) internal view returns (bytes memory) {
        return abi.encode(
            SettlementCallbackLib.SettlementParams(
                msg.sender,
                settlementParams.contractAddress,
                settlementParams.encodedData,
                settlementParams.maxQuoteAmount,
                settlementParams.price,
                settlementParams.fee
            )
        );
    }
}
