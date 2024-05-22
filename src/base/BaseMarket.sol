// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Owned} from "@solmate/src/auth/Owned.sol";
import "./BaseHookCallback.sol";
import {PredyPoolQuoter} from "../lens/PredyPoolQuoter.sol";
import "../interfaces/IFillerMarket.sol";
import "./SettlementCallbackLib.sol";

abstract contract BaseMarket is IFillerMarket, BaseHookCallback, Owned {
    address public whitelistFiller;

    PredyPoolQuoter internal immutable _quoter;

    mapping(uint256 pairId => address quoteTokenAddress) internal _quoteTokenMap;

    mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

    constructor(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)
        BaseHookCallback(predyPool)
        Owned(msg.sender)
    {
        whitelistFiller = _whitelistFiller;

        _quoter = PredyPoolQuoter(quoterAddress);
    }

    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external onlyPredyPool {
        SettlementCallbackLib.SettlementParams memory settlementParams =
            SettlementCallbackLib.decodeParams(settlementData);
        SettlementCallbackLib.validate(_whiteListedSettlements, settlementParams);
        SettlementCallbackLib.execSettlement(_predyPool, quoteToken, baseToken, settlementParams, baseAmountDelta);
    }

    function reallocate(uint256 pairId, IFillerMarket.SettlementParams memory settlementParams)
        external
        returns (bool relocationOccurred)
    {
        return _predyPool.reallocate(pairId, _getSettlementData(settlementParams));
    }

    function execLiquidationCall(
        uint256 vaultId,
        uint256 closeRatio,
        IFillerMarket.SettlementParams memory settlementParams
    ) external returns (IPredyPool.TradeResult memory) {
        return _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementData(settlementParams));
    }

    function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams)
        internal
        view
        returns (bytes memory)
    {
        return _getSettlementData(settlementParams, msg.sender);
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

    /**
     * @notice Updates the whitelist filler address
     * @dev only owner can call this function
     */
    function updateWhitelistFiller(address newWhitelistFiller) external onlyOwner {
        whitelistFiller = newWhitelistFiller;
    }

    /**
     * @notice Updates the whitelist settlement address
     * @dev only owner can call this function
     */
    function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyOwner {
        _whiteListedSettlements[settlementContractAddress] = isEnabled;
    }

    /// @notice Registers quote token address for the pair
    function updateQuoteTokenMap(uint256 pairId) external {
        if (_quoteTokenMap[pairId] == address(0)) {
            _quoteTokenMap[pairId] = _getQuoteTokenAddress(pairId);
        }
    }

    /// @notice Checks if entryTokenAddress is registerd for the pair
    function _validateQuoteTokenAddress(uint256 pairId, address entryTokenAddress) internal view {
        require(_quoteTokenMap[pairId] != address(0) && entryTokenAddress == _quoteTokenMap[pairId]);
    }

    function _getQuoteTokenAddress(uint256 pairId) internal view returns (address) {
        DataType.PairStatus memory pairStatus = _predyPool.getPairStatus(pairId);

        return pairStatus.quotePool.token;
    }

    function _revertTradeResult(IPredyPool.TradeResult memory tradeResult) internal pure {
        bytes memory data = abi.encode(tradeResult);

        assembly {
            revert(add(32, data), mload(data))
        }
    }
}
