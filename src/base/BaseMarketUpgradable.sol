// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {BaseHookCallbackUpgradable} from "./BaseHookCallbackUpgradable.sol";
import {PredyPoolQuoter} from "../lens/PredyPoolQuoter.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {DataType} from "../libraries/DataType.sol";
import "../interfaces/IFillerMarket.sol";
import "./SettlementCallbackLib.sol";

abstract contract BaseMarketUpgradable is IFillerMarket, BaseHookCallbackUpgradable {
    struct SettlementParamsV3Internal {
        address filler;
        address contractAddress;
        bytes encodedData;
        uint256 maxQuoteAmountPrice;
        uint256 minQuoteAmountPrice;
        uint256 price;
        uint256 feePrice;
        uint256 minFee;
    }

    address public whitelistFiller;

    PredyPoolQuoter internal _quoter;

    mapping(uint256 pairId => address quoteTokenAddress) internal _quoteTokenMap;

    mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

    modifier onlyFiller() {
        if (msg.sender != whitelistFiller) revert CallerIsNotFiller();
        _;
    }

    constructor() {}

    function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)
        internal
        onlyInitializing
    {
        __BaseHookCallback_init(predyPool);

        whitelistFiller = _whitelistFiller;

        _quoter = PredyPoolQuoter(quoterAddress);
    }

    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external onlyPredyPool {
        SettlementCallbackLib.SettlementParams memory settlementParams = decodeParamsV3(settlementData, baseAmountDelta);

        SettlementCallbackLib.validate(_whiteListedSettlements, settlementParams);
        SettlementCallbackLib.execSettlement(_predyPool, quoteToken, baseToken, settlementParams, baseAmountDelta);
    }

    function decodeParamsV3(bytes memory settlementData, int256 baseAmountDelta)
        internal
        pure
        returns (SettlementCallbackLib.SettlementParams memory)
    {
        SettlementParamsV3Internal memory settlementParamsV3 = abi.decode(settlementData, (SettlementParamsV3Internal));

        uint256 tradeAmountAbs = Math.abs(baseAmountDelta);

        uint256 fee = settlementParamsV3.feePrice * tradeAmountAbs / Constants.Q96;

        if (fee < settlementParamsV3.minFee) {
            fee = settlementParamsV3.minFee;
        }

        uint256 maxQuoteAmount = settlementParamsV3.maxQuoteAmountPrice * tradeAmountAbs / Constants.Q96;
        uint256 minQuoteAmount = settlementParamsV3.minQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

        return SettlementCallbackLib.SettlementParams(
            settlementParamsV3.filler,
            settlementParamsV3.contractAddress,
            settlementParamsV3.encodedData,
            baseAmountDelta > 0 ? minQuoteAmount : maxQuoteAmount,
            settlementParamsV3.price,
            int256(fee)
        );
    }

    function reallocate(uint256 pairId, IFillerMarket.SettlementParamsV3 memory settlementParams)
        external
        returns (bool relocationOccurred)
    {
        return _predyPool.reallocate(pairId, _getSettlementDataFromV3(settlementParams, msg.sender));
    }

    function execLiquidationCall(
        uint256 vaultId,
        uint256 closeRatio,
        IFillerMarket.SettlementParamsV3 memory settlementParams
    ) external virtual returns (IPredyPool.TradeResult memory) {
        return
            _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementDataFromV3(settlementParams, msg.sender));
    }

    function _getSettlementDataFromV3(IFillerMarket.SettlementParamsV3 memory settlementParams, address filler)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(
            SettlementParamsV3Internal(
                filler,
                settlementParams.contractAddress,
                settlementParams.encodedData,
                settlementParams.maxQuoteAmountPrice,
                settlementParams.minQuoteAmountPrice,
                settlementParams.price,
                settlementParams.feePrice,
                settlementParams.minFee
            )
        );
    }

    /**
     * @notice Updates the whitelist filler address
     * @dev only owner can call this function
     */
    function updateWhitelistFiller(address newWhitelistFiller) external onlyFiller {
        whitelistFiller = newWhitelistFiller;
    }

    function updateQuoter(address newQuoter) external onlyFiller {
        _quoter = PredyPoolQuoter(newQuoter);
    }

    /**
     * @notice Updates the whitelist settlement address
     * @dev only owner can call this function
     */
    function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyFiller {
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
