// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IPredyPool.sol";
import "../interfaces/IFillerMarket.sol";
import "../base/BaseHookCallback.sol";
import "../base/SettlementCallbackLib.sol";

/**
 * @notice Quoter contract for PredyPool
 * The purpose of lens is to be able to simulate transactions without having tokens.
 */
contract PredyPoolQuoter is BaseHookCallback {
    constructor(IPredyPool _predyPool) BaseHookCallback(_predyPool) {}

    function predySettlementCallback(address quoteToken, address baseToken, bytes memory data, int256 baseAmountDelta)
        external
    {
        if (data.length > 0) {
            SettlementCallbackLib.execSettlement(
                _predyPool, quoteToken, baseToken, SettlementCallbackLib.decodeParams(data), baseAmountDelta
            );
        } else {
            _revertBaseAmountDelta(baseAmountDelta);
        }
    }

    function _revertBaseAmountDelta(int256 baseAmountDelta) internal pure {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, baseAmountDelta)
            revert(ptr, 32)
        }
    }

    function predyTradeAfterCallback(IPredyPool.TradeParams memory, IPredyPool.TradeResult memory tradeResult)
        external
        view
        override(BaseHookCallback)
        onlyPredyPool
    {
        bytes memory data = abi.encode(tradeResult);

        assembly {
            revert(add(32, data), mload(data))
        }
    }

    /**
     * @notice Quotes trade
     * @param tradeParams The trade details
     * @param settlementParams The route of settlement created by filler
     */
    function quoteTrade(
        IPredyPool.TradeParams memory tradeParams,
        IFillerMarket.SettlementParams memory settlementParams
    ) external returns (IPredyPool.TradeResult memory tradeResult) {
        try _predyPool.trade(tradeParams, _getSettlementData(settlementParams, msg.sender)) {}
        catch (bytes memory reason) {
            tradeResult = _parseRevertReasonAsTradeResult(reason);
        }
    }

    function quoteBaseAmountDelta(IPredyPool.TradeParams memory tradeParams)
        external
        returns (int256 baseAmountDelta)
    {
        try _predyPool.trade(tradeParams, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quoteLiquidation(uint256 vaultId, uint256 closeRatio) external returns (int256 baseAmountDelta) {
        try _predyPool.execLiquidationCall(vaultId, closeRatio, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quoteReallocation(uint256 pairId) external returns (int256 baseAmountDelta) {
        try _predyPool.reallocate(pairId, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quotePairStatus(uint256 pairId) external returns (DataType.PairStatus memory pairStatus) {
        try _predyPool.revertPairStatus(pairId) {}
        catch (bytes memory reason) {
            pairStatus = _parseRevertReasonAsPairStatus(reason);
        }
    }

    function quoteVaultStatus(uint256 vaultId) external returns (IPredyPool.VaultStatus memory vaultStatus) {
        try _predyPool.revertVaultStatus(vaultId) {}
        catch (bytes memory reason) {
            vaultStatus = _parseRevertReasonAsVaultStatus(reason);
        }
    }

    /// @notice Return the tradeResult of given abi-encoded trade result
    /// @param tradeResult abi-encoded order, including `reactor` as the first encoded struct member
    function _parseRevertReasonAsTradeResult(bytes memory reason)
        private
        pure
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        if (reason.length != 384) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (IPredyPool.TradeResult));
        }
    }

    function _parseRevertReasonAsBaseAmountDelta(bytes memory reason) private pure returns (int256) {
        if (reason.length != 32) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }

        return abi.decode(reason, (int256));
    }

    function _parseRevertReasonAsPairStatus(bytes memory reason)
        private
        pure
        returns (DataType.PairStatus memory pairStatus)
    {
        if (reason.length != 1952) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (DataType.PairStatus));
        }
    }

    function _parseRevertReasonAsVaultStatus(bytes memory reason)
        private
        pure
        returns (IPredyPool.VaultStatus memory vaultStatus)
    {
        if (reason.length < 320) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (IPredyPool.VaultStatus));
        }
    }

    function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams, address filler)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(
            SettlementCallbackLib.SettlementParams(
                filler,
                settlementParams.contractAddress,
                settlementParams.encodedData,
                settlementParams.maxQuoteAmount,
                settlementParams.price,
                settlementParams.fee
            )
        );
    }
}
