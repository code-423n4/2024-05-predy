# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 44 |
| [GAS-2](#GAS-2) | Using bools for storage incurs overhead | 6 |
| [GAS-3](#GAS-3) | Cache array length outside of loop | 2 |
| [GAS-4](#GAS-4) | For Operations that will not overflow, you could use unchecked | 553 |
| [GAS-5](#GAS-5) | Use Custom Errors instead of Revert Strings to save Gas | 22 |
| [GAS-6](#GAS-6) | Avoid contract existence checks by using low level calls | 4 |
| [GAS-7](#GAS-7) | Functions guaranteed to revert when called by normal users can be marked `payable` | 19 |
| [GAS-8](#GAS-8) | `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`) | 5 |
| [GAS-9](#GAS-9) | Using `private` rather than `public` for constants, saves gas | 2 |
| [GAS-10](#GAS-10) | Use shift right/left instead of division/multiplication if possible | 5 |
| [GAS-11](#GAS-11) | Splitting require() statements that use && saves gas | 7 |
| [GAS-12](#GAS-12) | `uint256` to `bool` `mapping`: Utilizing Bitmaps to dramatically save on Gas | 1 |
| [GAS-13](#GAS-13) | Increments/decrements can be unchecked in for-loops | 2 |
| [GAS-14](#GAS-14) | Use != 0 instead of > 0 for unsigned integer comparison | 57 |
### <a name="GAS-1"></a>[GAS-1] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)
This saves **16 gas per instance.**

*Instances (44)*:
```solidity
File: src/libraries/ApplyInterestLib.sol

71:         poolStatus.accumulatedProtocolRevenue += totalProtocolFee / 2;

72:         poolStatus.accumulatedCreatorRevenue += totalProtocolFee / 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/InterestRateModel.sol

26:             ir += (utilizationRatio * irmParams.slope1) / _ONE;

28:             ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;

29:             ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/InterestRateModel.sol)

```solidity
File: src/libraries/Perp.sol

166:             _sqrtAssetStatus.rebalanceInterestGrowthBase += _pairStatus.basePool.tokenStatus.settleUserFee(

170:             _sqrtAssetStatus.rebalanceInterestGrowthQuote += _pairStatus.quotePool.tokenStatus.settleUserFee(

353:         _userStatus.sqrtPerp.baseRebalanceEntryValue += deltaPositionUnderlying;

354:         _userStatus.sqrtPerp.quoteRebalanceEntryValue += deltaPositionStable;

398:         _assetStatus.fee0Growth += FullMath.mulDiv(

401:         _assetStatus.fee1Growth += FullMath.mulDiv(

405:         _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);

406:         _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

498:         _userStatus.perp.amount += _updatePerpParams.tradeAmount;

501:         _userStatus.perp.entryValue += payoff.perpEntryUpdate;

502:         _userStatus.sqrtPerp.entryValue += payoff.sqrtEntryUpdate;

503:         _userStatus.sqrtPerp.quoteRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateStable;

504:         _userStatus.sqrtPerp.baseRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateUnderlying;

561:             _assetStatus.totalAmount += uint256(openAmount);

570:             _assetStatus.borrowedAmount += uint256(-openAmount);

576:         _userStatus.sqrtPerp.amount += _amount;

785:             offsetStable += closeAmount * _userStatus.sqrtPerp.quoteRebalanceEntryValue / _userStatus.sqrtPerp.amount;

786:             offsetUnderlying += closeAmount * _userStatus.sqrtPerp.baseRebalanceEntryValue / _userStatus.sqrtPerp.amount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PerpFee.sol

28:             FeeAmountUnderlying += rebalanceInterestBase;

29:             FeeAmountStable += rebalanceInterestQuote;

34:             FeeAmountUnderlying += feeUnderlying;

35:             FeeAmountStable += feeStable;

57:         totalFeeStable += feeStable + rebalanceInterestQuote;

58:         totalFeeUnderlying += feeUnderlying + rebalanceInterestBase;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/PositionCalculator.sol

123:         minValue += calculateMinValue(sqrtPrice, positionParams, riskRatio);

125:         vaultValue += calculateValue(sqrtPrice, positionParams);

127:         debtValue += calculateSquartDebtValue(sqrtPrice, positionParams);

131:         minValue += marginAmount;

132:         vaultValue += marginAmount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/Reallocation.sol

137:         minLowerTick += tickSpacing;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/ScaledAsset.sol

44:         tokenState.totalCompoundDeposited += claimAmount;

114:             tokenStatus.totalNormalDeposited += uint256(openAmount);

120:             tokenStatus.totalNormalBorrowed += uint256(-openAmount);

125:         userStatus.positionAmount += _amount;

209:         tokenState.debtGrowth += _interestRate;

212:         tokenState.assetGrowth += supplyInterestRate;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

69:         vault.margin += tradeResult.fee + tradeResult.payoff.perpPayoff + tradeResult.payoff.sqrtPayoff;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/TradeLogic.sol

44:         globalData.vaults[tradeParams.vaultId].margin +=

83:         globalData.vaults[tradeParams.vaultId].margin += marginAmountUpdate;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/TradeLogic.sol)

### <a name="GAS-2"></a>[GAS-2] Using bools for storage incurs overhead
Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (6)*:
```solidity
File: src/PredyPool.sol

38:     mapping(address => bool) public allowedUniswapPools;

40:     mapping(address trader => mapping(uint256 pairId => bool)) public allowedTraders;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseMarket.sol

17:     mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

29:     mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

30:         mapping(address settlementContractAddress => bool) storage _whiteListedSettlements,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

55:         mapping(address => bool) storage allowedUniswapPools,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

### <a name="GAS-3"></a>[GAS-3] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (2)*:
```solidity
File: src/markets/gamma/ArrayLib.sol

23:         for (uint256 i = 0; i < items.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

366:         for (uint64 i = 0; i < userPositionIDs.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

### <a name="GAS-4"></a>[GAS-4] For Operations that will not overflow, you could use unchecked

*Instances (553)*:
```solidity
File: src/PredyPool.sol

4: import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

5: import {IUniswapV3MintCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";

6: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

7: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

9: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

10: import {IPredyPool} from "./interfaces/IPredyPool.sol";

11: import {IHooks} from "./interfaces/IHooks.sol";

12: import {ISettlement} from "./interfaces/ISettlement.sol";

13: import {Perp} from "./libraries/Perp.sol";

14: import {VaultLib} from "./libraries/VaultLib.sol";

15: import {PositionCalculator} from "./libraries/PositionCalculator.sol";

16: import {DataType} from "./libraries/DataType.sol";

17: import {InterestRateModel} from "./libraries/InterestRateModel.sol";

18: import {UniHelper} from "./libraries/UniHelper.sol";

19: import {AddPairLogic} from "./libraries/logic/AddPairLogic.sol";

20: import {LiquidationLogic} from "./libraries/logic/LiquidationLogic.sol";

21: import {ReallocationLogic} from "./libraries/logic/ReallocationLogic.sol";

22: import {SupplyLogic} from "./libraries/logic/SupplyLogic.sol";

23: import {TradeLogic} from "./libraries/logic/TradeLogic.sol";

24: import {ReaderLogic} from "./libraries/logic/ReaderLogic.sol";

25: import {LockDataLibrary, GlobalDataLibrary} from "./types/GlobalData.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/PriceFeed.sol

4: import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";

5: import {AggregatorV3Interface} from "./vendors/AggregatorV3Interface.sol";

6: import {IPyth} from "./vendors/IPyth.sol";

7: import {Constants} from "./libraries/Constants.sol";

35:     uint256 private constant VALID_TIME_PERIOD = 5 * 60;

50:         require(basePrice.expo == -8, "INVALID_EXP");

54:         uint256 price = uint256(int256(basePrice.price)) * Constants.Q96 / uint256(quoteAnswer);

55:         price = price * Constants.Q96 / _decimalsDiff;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseHookCallback.sol

4: import "../interfaces/IPredyPool.sol";

5: import "../interfaces/IHooks.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallback.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

4: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

5: import "../interfaces/IPredyPool.sol";

6: import "../interfaces/IHooks.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarket.sol

4: import {Owned} from "@solmate/src/auth/Owned.sol";

5: import "./BaseHookCallback.sol";

6: import {PredyPoolQuoter} from "../lens/PredyPoolQuoter.sol";

7: import "../interfaces/IFillerMarket.sol";

8: import "./SettlementCallbackLib.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

4: import {BaseHookCallbackUpgradable} from "./BaseHookCallbackUpgradable.sol";

5: import {PredyPoolQuoter} from "../lens/PredyPoolQuoter.sol";

6: import {IPredyPool} from "../interfaces/IPredyPool.sol";

7: import {DataType} from "../libraries/DataType.sol";

8: import "../interfaces/IFillerMarket.sol";

9: import "./SettlementCallbackLib.sol";

70:         uint256 fee = settlementParamsV3.feePrice * tradeAmountAbs / Constants.Q96;

76:         uint256 maxQuoteAmount = settlementParamsV3.maxQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

77:         uint256 minQuoteAmount = settlementParamsV3.minQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {IPredyPool} from "../interfaces/IPredyPool.sol";

7: import {ISettlement} from "../interfaces/ISettlement.sol";

8: import {Constants} from "../libraries/Constants.sol";

9: import {Math} from "../libraries/math/Math.sol";

10: import {IFillerMarket} from "../interfaces/IFillerMarket.sol";

49:                 settlementParams.sender, address(predyPool), uint256(-settlementParams.fee)

85:                 uint256(-baseAmountDelta)

101:             uint256 quoteAmount = sellAmount * price / Constants.Q96;

125:             uint256 quoteAmount = sellAmount * price / Constants.Q96;

128:                 ERC20(quoteToken).safeTransferFrom(sender, address(this), quoteAmount - quoteAmountFromUni);

130:                 ERC20(quoteToken).safeTransfer(sender, quoteAmountFromUni - quoteAmount);

148:             uint256 quoteAmount = buyAmount * price / Constants.Q96;

170:             ERC20(quoteToken).safeTransfer(address(predyPool), settlementParams.maxQuoteAmount - quoteAmountToUni);

172:             uint256 quoteAmount = buyAmount * price / Constants.Q96;

175:                 ERC20(quoteToken).safeTransfer(sender, quoteAmount - quoteAmountToUni);

177:                 ERC20(quoteToken).safeTransferFrom(sender, address(this), quoteAmountToUni - quoteAmount);

180:             ERC20(quoteToken).safeTransfer(address(predyPool), settlementParams.maxQuoteAmount - quoteAmount);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/ApplyInterestLib.sol

4: import "./Perp.sol";

5: import "./ScaledAsset.sol";

6: import "./DataType.sol";

71:         poolStatus.accumulatedProtocolRevenue += totalProtocolFee / 2;

72:         poolStatus.accumulatedCreatorRevenue += totalProtocolFee / 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/Constants.sol

32:     uint256 internal constant SQUART_KINK_UR = 10 * 1e16;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Constants.sol)

```solidity
File: src/libraries/DataType.sol

4: import {Perp} from "./Perp.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/DataType.sol)

```solidity
File: src/libraries/InterestRateModel.sol

26:             ir += (utilizationRatio * irmParams.slope1) / _ONE;

28:             ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;

29:             ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/InterestRateModel.sol)

```solidity
File: src/libraries/PairLib.sol

6:         return pairId * type(uint64).max + rebalanceId;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PairLib.sol)

```solidity
File: src/libraries/Perp.sol

4: import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

5: import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";

6: import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

7: import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

8: import "@solmate/src/utils/SafeCastLib.sol";

9: import "@openzeppelin/contracts/utils/math/SafeCast.sol";

10: import {IPredyPool} from "../interfaces/IPredyPool.sol";

11: import "./ScaledAsset.sol";

12: import "./InterestRateModel.sol";

13: import "./PremiumCurveModel.sol";

14: import "./Constants.sol";

15: import {DataType} from "./DataType.sol";

16: import "./UniHelper.sol";

17: import "./math/LPMath.sol";

18: import "./math/Math.sol";

19: import "./Reallocation.sol";

166:             _sqrtAssetStatus.rebalanceInterestGrowthBase += _pairStatus.basePool.tokenStatus.settleUserFee(

168:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

170:             _sqrtAssetStatus.rebalanceInterestGrowthQuote += _pairStatus.quotePool.tokenStatus.settleUserFee(

172:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

210:             _sqrtAssetStatus.tickLower + _assetStatusUnderlying.riskParams.rebalanceThreshold < currentTick

211:                 && currentTick < _sqrtAssetStatus.tickUpper - _assetStatusUnderlying.riskParams.rebalanceThreshold

286:             int256(receivedAmount0) - int256(requiredAmount0),

287:             int256(receivedAmount1) - int256(requiredAmount1)

322:             deltaPositionQuote = -deltaPosition0;

323:             deltaPositionBase = -deltaPosition1;

325:             deltaPositionBase = -deltaPosition0;

326:             deltaPositionQuote = -deltaPosition1;

353:         _userStatus.sqrtPerp.baseRebalanceEntryValue += deltaPositionUnderlying;

354:         _userStatus.sqrtPerp.quoteRebalanceEntryValue += deltaPositionStable;

359:             _pairStatus.sqrtAssetStatus.rebalancePositionBase, -deltaPositionUnderlying, _pairStatus.id, false

362:             _pairStatus.sqrtAssetStatus.rebalancePositionQuote, -deltaPositionStable, _pairStatus.id, true

386:             f0 = feeGrowthInside0X128 - _assetStatus.lastFee0Growth;

387:             f1 = feeGrowthInside1X128 - _assetStatus.lastFee1Growth;

398:         _assetStatus.fee0Growth += FullMath.mulDiv(

399:             f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

401:         _assetStatus.fee1Growth += FullMath.mulDiv(

402:             f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

405:         _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);

406:         _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

451:             (requiredAmount0, requiredAmount1) = decrease(_sqrtAssetStatus, uint256(-_tradeSqrtAmount));

466:         requiredAmountUnderlying -= offsetUnderlying;

467:         requiredAmountStable -= offsetStable;

498:         _userStatus.perp.amount += _updatePerpParams.tradeAmount;

501:         _userStatus.perp.entryValue += payoff.perpEntryUpdate;

502:         _userStatus.sqrtPerp.entryValue += payoff.sqrtEntryUpdate;

503:         _userStatus.sqrtPerp.quoteRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateStable;

504:         _userStatus.sqrtPerp.baseRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateUnderlying;

513:             _updatePerpParams.tradeAmount + payoff.sqrtRebalanceEntryUpdateUnderlying,

520:             payoff.perpEntryUpdate + payoff.sqrtEntryUpdate + payoff.sqrtRebalanceEntryUpdateStable,

535:         if (_userStatus.sqrtPerp.amount * _amount >= 0) {

541:                 openAmount = _userStatus.sqrtPerp.amount + _amount;

542:                 closeAmount = -_userStatus.sqrtPerp.amount;

552:             _assetStatus.borrowedAmount -= uint256(closeAmount);

554:             if (getAvailableSqrtAmount(_assetStatus, true) < uint256(-closeAmount)) {

557:             _assetStatus.totalAmount -= uint256(-closeAmount);

561:             _assetStatus.totalAmount += uint256(openAmount);

566:             if (getAvailableSqrtAmount(_assetStatus, false) < uint256(-openAmount)) {

570:             _assetStatus.borrowedAmount += uint256(-openAmount);

576:         _userStatus.sqrtPerp.amount += _amount;

590:         uint256 buffer = Math.max(_assetStatus.totalAmount / 50, Constants.MIN_LIQUIDITY);

591:         uint256 available = _assetStatus.totalAmount - _assetStatus.borrowedAmount;

598:             return available - buffer;

609:         uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

660:             deltaPosition0 = -deltaPosition0;

661:             deltaPosition1 = -deltaPosition1;

682:         if (_positionAmount * _tradeAmount >= 0) {

689:                 int256 closeStableAmount = _entryValue * _tradeAmount / _positionAmount;

692:                 payoff = _valueUpdate - closeStableAmount;

696:                 int256 closeStableAmount = -_entryValue;

697:                 int256 openStableAmount = _valueUpdate * (_positionAmount + _tradeAmount) / _tradeAmount;

699:                 deltaEntry = closeStableAmount + openStableAmount;

700:                 payoff = _valueUpdate - closeStableAmount - openStableAmount;

715:         requiredAmount0 = -SafeCast.toInt256(amount0);

716:         requiredAmount1 = -SafeCast.toInt256(amount1);

723:         if (_assetStatus.totalAmount - _assetStatus.borrowedAmount < _liquidityAmount) {

755:         if (_userStatus.sqrtPerp.amount * _tradeSqrtAmount >= 0) {

761:                 openAmount = _userStatus.sqrtPerp.amount + _tradeSqrtAmount;

762:                 closeAmount = -_userStatus.sqrtPerp.amount;

774:                 offsetUnderlying = -offsetUnderlying;

775:                 offsetStable = -offsetStable;

785:             offsetStable += closeAmount * _userStatus.sqrtPerp.quoteRebalanceEntryValue / _userStatus.sqrtPerp.amount;

786:             offsetUnderlying += closeAmount * _userStatus.sqrtPerp.baseRebalanceEntryValue / _userStatus.sqrtPerp.amount;

817:         sqrtPerpStatus.lastRebalanceTotalSquartAmount = sqrtPerpStatus.totalAmount + sqrtPerpStatus.borrowedAmount;

818:         sqrtPerpStatus.numRebalance++;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PerpFee.sol

4: import "@openzeppelin/contracts/utils/math/SafeCast.sol";

5: import "./PairLib.sol";

6: import "./Perp.sol";

7: import "./DataType.sol";

8: import "./Constants.sol";

9: import {ScaledAsset} from "./ScaledAsset.sol";

10: import {Math} from "./math/Math.sol";

28:             FeeAmountUnderlying += rebalanceInterestBase;

29:             FeeAmountStable += rebalanceInterestQuote;

34:             FeeAmountUnderlying += feeUnderlying;

35:             FeeAmountStable += feeStable;

57:         totalFeeStable += feeStable + rebalanceInterestQuote;

58:         totalFeeUnderlying += feeUnderlying + rebalanceInterestBase;

74:             growthDiff0 = baseAssetStatus.sqrtAssetStatus.fee0Growth - sqrtPerp.entryTradeFee0;

75:             growthDiff1 = baseAssetStatus.sqrtAssetStatus.fee1Growth - sqrtPerp.entryTradeFee1;

77:             growthDiff0 = baseAssetStatus.sqrtAssetStatus.borrowPremium0Growth - sqrtPerp.entryTradeFee0;

78:             growthDiff1 = baseAssetStatus.sqrtAssetStatus.borrowPremium1Growth - sqrtPerp.entryTradeFee1;

123:                 assetStatus.rebalanceInterestGrowthBase - rebalanceFeeGrowthCache[rebalanceId].underlyingGrowth,

128:                 assetStatus.rebalanceInterestGrowthQuote - rebalanceFeeGrowthCache[rebalanceId].stableGrowth,

148:             assetStatus.lastRebalanceTotalSquartAmount -= rebalanceAmount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/PositionCalculator.sol

4: import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

5: import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

6: import "@openzeppelin/contracts/utils/math/SafeCast.sol";

7: import "./UniHelper.sol";

8: import "./Perp.sol";

9: import "./DataType.sol";

10: import "./Constants.sol";

11: import "./math/Math.sol";

12: import "../PriceFeed.sol";

93:             (calculateRequiredCollateralWithDebt(pairStatus.riskParams.debtRiskRatio) * debtValue).toInt256() / 1e6;

95:         minMargin = vaultValue - minValue + minMinValue;

123:         minValue += calculateMinValue(sqrtPrice, positionParams, riskRatio);

125:         vaultValue += calculateValue(sqrtPrice, positionParams);

127:         debtValue += calculateSquartDebtValue(sqrtPrice, positionParams);

131:         minValue += marginAmount;

132:         vaultValue += marginAmount;

157:             perpUserStatus.perp.entryValue + perpUserStatus.sqrtPerp.entryValue + feeAmount.feeAmountQuote,

159:             perpUserStatus.perp.amount + feeAmount.feeAmountBase

169:             _perpUserStatus.perp.entryValue + _perpUserStatus.sqrtPerp.entryValue,

193:         uint256 upperPrice = _sqrtPrice * _riskRatio / RISK_RATIO_ONE;

194:         uint256 lowerPrice = _sqrtPrice * RISK_RATIO_ONE / _riskRatio;

213:                 (uint256(-_positionParams.amountSqrt) * Constants.Q96) / uint256(_positionParams.amountBase);

235:             + Math.fullMulDivInt256(2 * _positionParams.amountSqrt, _sqrtPrice, Constants.Q96) + _positionParams.amountQuote;

249:         return (2 * (uint256(-squartPosition) * _sqrtPrice) >> Constants.RESOLUTION);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/PremiumCurveModel.sol

4: import "./Constants.sol";

19:         uint256 b = (utilization - Constants.SQUART_KINK_UR);

21:         return (1600 * b * b / Constants.ONE) / Constants.ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PremiumCurveModel.sol)

```solidity
File: src/libraries/Reallocation.sol

4: import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

5: import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

6: import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

7: import "@openzeppelin/contracts/utils/math/SafeCast.sol";

8: import {DataType} from "./DataType.sol";

9: import "./Perp.sol";

10: import "./ScaledAsset.sol";

48:         lower = currentTick - _assetStatusUnderlying.riskParams.rangeSize;

49:         upper = currentTick + _assetStatusUnderlying.riskParams.rangeSize;

51:         int24 previousCenterTick = (sqrtAssetStatus.tickLower + sqrtAssetStatus.tickUpper) / 2;

53:         uint256 availableAmount = sqrtAssetStatus.totalAmount - sqrtAssetStatus.borrowedAmount;

67:                     upper = lower + _assetStatusUnderlying.riskParams.rangeSize * 2;

80:                     lower = upper - _assetStatusUnderlying.riskParams.rangeSize * 2;

120:         result = (result / tickSpacing) * tickSpacing;

137:         minLowerTick += tickSpacing;

139:         if (minLowerTick > currentLowerTick - tickSpacing) {

140:             minLowerTick = currentLowerTick - tickSpacing;

158:         maxUpperTick -= tickSpacing;

160:         if (maxUpperTick < currentUpperTick + tickSpacing) {

161:             maxUpperTick = currentUpperTick + tickSpacing;

170:         uint160 sqrtPrice = (available * FixedPoint96.Q96 / liquidityAmount).toUint160();

172:         if (sqrtRatioA <= sqrtPrice + TickMath.MIN_SQRT_RATIO) {

173:             return TickMath.MIN_SQRT_RATIO + 1;

176:         return sqrtRatioA - sqrtPrice;

184:         uint256 denominator1 = available * sqrtRatioB / FixedPoint96.Q96;

187:             return TickMath.MAX_SQRT_RATIO - 1;

190:         uint160 sqrtPrice = uint160(liquidityAmount * sqrtRatioB / (liquidityAmount - denominator1));

193:             return TickMath.MIN_SQRT_RATIO + 1;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/ScaledAsset.sol

4: import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";

5: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

6: import {Constants} from "./Constants.sol";

7: import {Math} from "./math/Math.sol";

44:         tokenState.totalCompoundDeposited += claimAmount;

69:         tokenState.totalCompoundDeposited -= finalBurnAmount;

99:                 openAmount = userStatus.positionAmount + _amount;

100:                 closeAmount = -userStatus.positionAmount;

105:             tokenStatus.totalNormalBorrowed -= uint256(closeAmount);

108:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-closeAmount), "S0");

110:             tokenStatus.totalNormalDeposited -= uint256(-closeAmount);

114:             tokenStatus.totalNormalDeposited += uint256(openAmount);

118:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-openAmount), "S0");

120:             tokenStatus.totalNormalBorrowed += uint256(-openAmount);

125:         userStatus.positionAmount += _amount;

138:             interestFee = -(getDebtFee(_assetStatus, _userStatus)).toInt256();

163:             tokenState.assetGrowth - accountState.lastFeeGrowth,

178:             tokenState.debtGrowth - accountState.lastFeeGrowth,

180:             uint256(-accountState.positionAmount),

205:             100 - _reserveFactor,

209:         tokenState.debtGrowth += _interestRate;

211:             FixedPointMathLib.mulDivDown(tokenState.assetScaler, Constants.ONE + supplyInterestRate, Constants.ONE);

212:         tokenState.assetGrowth += supplyInterestRate;

219:             + tokenState.totalNormalDeposited;

227:         return getTotalCollateralValue(tokenState) - getTotalDebtValue(tokenState);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/SlippageLib.sol

4: import {IPredyPool} from "../interfaces/IPredyPool.sol";

5: import {Constants} from "./Constants.sol";

6: import {Bps} from "./math/Bps.sol";

7: import {Math} from "./math/Math.sol";

40:             if (basePrice.upper(slippageTolerance) < uint256(-tradeResult.averagePrice)) {

48:                     tradeResult.sqrtPrice < sqrtBasePrice * 1e8 / maxAcceptableSqrtPriceRange

49:                         || sqrtBasePrice * maxAcceptableSqrtPriceRange / 1e8 < tradeResult.sqrtPrice

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/Trade.sol

4: import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

5: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

6: import {IPredyPool} from "../interfaces/IPredyPool.sol";

7: import {IHooks} from "../interfaces/IHooks.sol";

8: import {ISettlement} from "../interfaces/ISettlement.sol";

9: import {Constants} from "./Constants.sol";

10: import {DataType} from "./DataType.sol";

11: import {Perp} from "./Perp.sol";

12: import {PerpFee} from "./PerpFee.sol";

13: import {GlobalDataLibrary} from "../types/GlobalData.sol";

14: import {LockDataLibrary} from "../types/LockData.sol";

15: import {PositionCalculator} from "./PositionCalculator.sol";

16: import {Math} from "./math/Math.sol";

17: import {UniHelper} from "./UniHelper.sol";

56:             SwapStableResult(-tradeParams.tradeAmount, underlyingAmountForSqrt, realizedFee.feeAmountBase, 0),

69:             Perp.UpdateSqrtPerpParams(tradeParams.tradeAmountSqrt, swapResult.amountSqrtPerp + stableAmountForSqrt)

72:         tradeResult.fee = realizedFee.feeAmountQuote + swapResult.fee;

84:         int256 totalBaseAmount = swapParams.amountPerp + swapParams.amountSqrtPerp + swapParams.fee;

98:         if (settledBaseAmount != -totalBaseAmount) {

103:         if (settledQuoteAmount * totalBaseAmount <= 0) {

117:         uint256 quoteAmount = (currentSqrtPrice * baseAmount) >> Constants.RESOLUTION;

119:         return (quoteAmount * currentSqrtPrice) >> Constants.RESOLUTION;

128:         swapResult.amountPerp = amountQuote * swapParams.amountPerp / amountBase;

129:         swapResult.amountSqrtPerp = amountQuote * swapParams.amountSqrtPerp / amountBase;

130:         swapResult.fee = totalAmountStable - swapResult.amountPerp - swapResult.amountSqrtPerp;

132:         swapResult.averagePrice = amountQuote * int256(Constants.Q96) / Math.abs(amountBase).toInt256();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/UniHelper.sol

4: import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

5: import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

6: import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";

7: import "../vendors/IUniswapV3PoolOracle.sol";

8: import "./Constants.sol";

29:             return uint160((Constants.Q96 << Constants.RESOLUTION) / sqrtPriceX96);

51:             (uint32 oldestAvailableAge,,, bool initialized) = uniswapPool.observations((index + 1) % cardinality);

57:             ago = block.timestamp - oldestAvailableAge;

70:         int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int256(ago)));

84:         revert("e/empty-error");

122:                     feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;

123:                     feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;

139:                     feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;

140:                     feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;

144:             feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;

145:             feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/VaultLib.sol

4: import {IPredyPool} from "../interfaces/IPredyPool.sol";

5: import {DataType} from "./DataType.sol";

6: import {GlobalDataLibrary} from "../types/GlobalData.sol";

42:             globalData.vaultCount++;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/VaultLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

4: import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

5: import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

6: import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

7: import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

8: import {Perp} from "../Perp.sol";

9: import {Constants} from "../Constants.sol";

10: import {DataType} from "../DataType.sol";

11: import {InterestRateModel} from "../InterestRateModel.sol";

12: import {ScaledAsset} from "../ScaledAsset.sol";

13: import {SupplyToken} from "../../tokenization/SupplyToken.sol";

14: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

91:         _global.pairsCount++;

178:                 -_addPairParam.assetRiskParams.rangeSize,

198:                 string.concat("Predy6-Supply-", erc20.name()),

214:         require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

222:                 && _irmParams.slope2 <= 10 * 1e18,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

7: import {IHooks} from "../../interfaces/IHooks.sol";

8: import {ISettlement} from "../../interfaces/ISettlement.sol";

9: import {ApplyInterestLib} from "../ApplyInterestLib.sol";

10: import {Constants} from "../Constants.sol";

11: import {Perp} from "../Perp.sol";

12: import {PerpFee} from "../PerpFee.sol";

13: import {Trade} from "../Trade.sol";

14: import {Math} from "../math/Math.sol";

15: import {DataType} from "../DataType.sol";

16: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

17: import {PositionCalculator} from "../PositionCalculator.sol";

18: import {ScaledAsset} from "../ScaledAsset.sol";

19: import {SlippageLib} from "../SlippageLib.sol";

62:             -vault.openPosition.perp.amount * int256(closeRatio) / 1e18,

63:             -vault.openPosition.sqrtPerp.amount * int256(closeRatio) / 1e18,

69:         vault.margin += tradeResult.fee + tradeResult.payoff.perpPayoff + tradeResult.payoff.sqrtPayoff;

106:                 ERC20(pairStatus.quotePool.token).safeTransferFrom(msg.sender, address(this), uint256(-remainingMargin));

168:         uint256 ratio = uint256(vaultValue * 1e4 / minMargin);

174:         return (riskParams.maxSlippage - ratio * (riskParams.maxSlippage - riskParams.minSlippage) / 1e4);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/ReaderLogic.sol

4: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

5: import {Constants} from "../Constants.sol";

6: import {DataType} from "../DataType.sol";

7: import {Perp} from "../Perp.sol";

8: import {PerpFee} from "../PerpFee.sol";

9: import {ApplyInterestLib} from "../ApplyInterestLib.sol";

10: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

11: import {PositionCalculator} from "../PositionCalculator.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReaderLogic.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {ISettlement} from "../../interfaces/ISettlement.sol";

7: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

8: import {DataType} from "../DataType.sol";

9: import {Perp} from "../Perp.sol";

10: import {PairLib} from "../PairLib.sol";

11: import {ApplyInterestLib} from "../ApplyInterestLib.sol";

12: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

58:                 int256 exceedsQuote = settledQuoteAmount + deltaPositionQuote;

64:                 if (settledBaseAmount + deltaPositionBase != 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

7: import {ISupplyToken} from "../../interfaces/ISupplyToken.sol";

8: import {DataType} from "../DataType.sol";

9: import {Perp} from "../Perp.sol";

10: import {ScaledAsset} from "../ScaledAsset.sol";

11: import {ApplyInterestLib} from "../ApplyInterestLib.sol";

12: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/libraries/logic/TradeLogic.sol

4: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

5: import {IHooks} from "../../interfaces/IHooks.sol";

6: import {ISettlement} from "../../interfaces/ISettlement.sol";

7: import {ApplyInterestLib} from "../ApplyInterestLib.sol";

8: import {DataType} from "../DataType.sol";

9: import {Perp} from "../Perp.sol";

10: import {Trade} from "../Trade.sol";

11: import {GlobalDataLibrary} from "../../types/GlobalData.sol";

12: import {PositionCalculator} from "../PositionCalculator.sol";

13: import {ScaledAsset} from "../ScaledAsset.sol";

44:         globalData.vaults[tradeParams.vaultId].margin +=

45:             tradeResult.fee + tradeResult.payoff.perpPayoff + tradeResult.payoff.sqrtPayoff;

83:         globalData.vaults[tradeParams.vaultId].margin += marginAmountUpdate;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/TradeLogic.sol)

```solidity
File: src/libraries/math/Bps.sol

8:         return price * bps / ONE;

12:         return price * ONE / bps;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Bps.sol)

```solidity
File: src/libraries/math/LPMath.sol

4: import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

5: import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

6: import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

7: import "@openzeppelin/contracts/utils/math/SafeCast.sol";

53:             r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);

58:             r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);

62:             return -r;

90:             r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);

95:             r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);

99:             return -r;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/LPMath.sol)

```solidity
File: src/libraries/math/Math.sol

4: import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

5: import {FixedPointMathLib} from "@solmate/src/utils/FixedPointMathLib.sol";

6: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

7: import {Constants} from "../Constants.sol";

13:         return uint256(x >= 0 ? x : -x);

30:             return -FullMath.mulDiv(uint256(-x), y, z).toInt256();

40:             return -FullMath.mulDivRoundingUp(uint256(-x), y, z).toInt256();

50:             return -FixedPointMathLib.mulDivUp(uint256(-x), y, z).toInt256();

56:             return a + uint256(b);

58:             return a - uint256(-b);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Math.sol)

```solidity
File: src/libraries/orders/DecayLib.sol

28:             uint256 elapsed = value - decayStartTime;

29:             uint256 duration = decayEndTime - decayStartTime;

32:                 decayedPrice = startPrice - (startPrice - endPrice) * elapsed / duration;

34:                 decayedPrice = startPrice + (endPrice - startPrice) * elapsed / duration;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/DecayLib.sol)

```solidity
File: src/libraries/orders/Permit2Lib.sol

4: import {ISignatureTransfer} from "@uniswap/permit2/src/interfaces/ISignatureTransfer.sol";

5: import {ResolvedOrder} from "./ResolvedOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/Permit2Lib.sol)

```solidity
File: src/libraries/orders/ResolvedOrder.sol

4: import {OrderInfo} from "./OrderInfoLib.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/ResolvedOrder.sol)

```solidity
File: src/markets/gamma/ArrayLib.sol

16:         items[index] = items[items.length - 1];

23:         for (uint256 i = 0; i < items.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaOrder.sol

4: import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

6: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

7: import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaOrder.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

7: import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";

8: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

9: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

10: import {BaseMarketUpgradable} from "../../base/BaseMarketUpgradable.sol";

11: import {BaseHookCallbackUpgradable} from "../../base/BaseHookCallbackUpgradable.sol";

12: import {Permit2Lib} from "../../libraries/orders/Permit2Lib.sol";

13: import {ResolvedOrder, ResolvedOrderLib} from "../../libraries/orders/ResolvedOrder.sol";

14: import {SlippageLib} from "../../libraries/SlippageLib.sol";

15: import {Bps} from "../../libraries/math/Bps.sol";

16: import {DataType} from "../../libraries/DataType.sol";

17: import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";

18: import {ArrayLib} from "./ArrayLib.sol";

19: import {GammaTradeMarketLib} from "./GammaTradeMarketLib.sol";

109:                     -vault.margin,

120:                     _predyPool.take(true, callbackData.trader, uint256(-marginAmountUpdate));

263:             -delta,

301:             -vault.openPosition.perp.amount,

302:             -vault.openPosition.sqrtPerp.amount,

366:         for (uint64 i = 0; i < userPositionIDs.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketL2.sol

4: import {GammaTradeMarket} from "./GammaTradeMarket.sol";

5: import {OrderInfo} from "../../libraries/orders/OrderInfoLib.sol";

6: import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";

7: import {L2GammaDecoder} from "./L2GammaDecoder.sol";

8: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketL2.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

4: import {Bps} from "../../libraries/math/Bps.sol";

5: import {Constants} from "../../libraries/Constants.sol";

6: import {DataType} from "../../libraries/DataType.sol";

7: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

8: import {SlippageLib} from "../../libraries/SlippageLib.sol";

9: import {GammaModifyInfo} from "./GammaOrder.sol";

53:         int256 sqrtPrice = int256(_sqrtPrice) * (1e6 + maximaDeviation) / 1e6;

56:         return perpAmount + _sqrtAmount * int256(Constants.Q96) / sqrtPrice;

66:                 && userPosition.lastHedgedTime + userPosition.hedgeInterval <= block.timestamp

71:                     userPosition.lastHedgedTime + userPosition.hedgeInterval,

84:         uint256 upperThreshold = userPosition.lastHedgedSqrtPrice * userPosition.sqrtPriceTrigger / Bps.ONE;

85:         uint256 lowerThreshold = userPosition.lastHedgedSqrtPrice * Bps.ONE / userPosition.sqrtPriceTrigger;

150:         uint256 elapsed = (currentTime - startTime) * Bps.ONE / auctionParams.auctionPeriod;

158:                 + elapsed * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance) / Bps.ONE

176:         uint256 ratio = (price2 * Bps.ONE / price1 - Bps.ONE);

184:                 + ratio * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance)

185:                     / auctionParams.auctionRange

202:         require(modifyInfo.maxSlippageTolerance <= 2 * Bps.ONE);

203:         require(-1e6 < modifyInfo.maximaDeviation && modifyInfo.maximaDeviation < 1e6);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketWrapper.sol

4: import {GammaTradeMarketL2} from "./GammaTradeMarketL2.sol";

5: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

6: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

7: import {GammaOrder} from "./GammaOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketWrapper.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

4: import {GammaModifyInfo} from "./GammaOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

```solidity
File: src/markets/perp/PerpMarket.sol

4: import {PerpMarketV1} from "./PerpMarketV1.sol";

5: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

6: import {PerpOrderV3} from "./PerpOrderV3.sol";

7: import {OrderInfo} from "../../libraries/orders/OrderInfoLib.sol";

8: import {L2Decoder} from "../L2Decoder.sol";

9: import {Bps} from "../../libraries/math/Bps.sol";

10: import {DataType} from "../../libraries/DataType.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarket.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

4: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

5: import {Constants} from "../../libraries/Constants.sol";

6: import {DecayLib} from "../../libraries/orders/DecayLib.sol";

7: import {Bps} from "../../libraries/math/Bps.sol";

8: import {Math} from "../../libraries/math/Math.sol";

35:         int256 tradeAmount = isLong ? int256(quantity) : -int256(quantity);

46:             return -currentPositionAmount;

56:                     if (currentPositionAmount > -tradeAmount) {

59:                         return -currentPositionAmount;

66:                     if (-currentPositionAmount > tradeAmount) {

69:                         return -currentPositionAmount;

87:         uint256 tradePrice = Math.abs(tradeResult.payoff.perpEntryUpdate + tradeResult.payoff.perpPayoff)

182:             return (price1 - price2) * Bps.ONE / price2;

184:             return (price2 - price1) * Bps.ONE / price2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";

7: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

9: import "../../interfaces/IPredyPool.sol";

10: import {BaseMarketUpgradable} from "../../base/BaseMarketUpgradable.sol";

11: import {BaseHookCallbackUpgradable} from "../../base/BaseHookCallbackUpgradable.sol";

12: import "../../libraries/orders/Permit2Lib.sol";

13: import "../../libraries/orders/ResolvedOrder.sol";

14: import {SlippageLib} from "../../libraries/SlippageLib.sol";

15: import {PositionCalculator} from "../../libraries/PositionCalculator.sol";

16: import {Constants} from "../../libraries/Constants.sol";

17: import {Perp} from "../../libraries/Perp.sol";

18: import {Bps} from "../../libraries/math/Bps.sol";

19: import {Math} from "../../libraries/math/Math.sol";

20: import "./PerpOrder.sol";

21: import "./PerpOrderV3.sol";

22: import {PredyPoolQuoter} from "../../lens/PredyPoolQuoter.sol";

23: import {SettlementCallbackLib} from "../../base/SettlementCallbackLib.sol";

24: import {PerpMarketLib} from "./PerpMarketLib.sol";

128:                 _predyPool.take(true, callbackData.trader, uint256(-marginAmountUpdate));

233:         return (netValue / leverage).toInt256() - _calculatePositionValue(vault, sqrtPrice);

239:         return Math.abs(positionAmount) * price / Constants.Q96;

244:             + vault.margin;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/markets/perp/PerpOrder.sol

4: import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

6: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

7: import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrder.sol)

```solidity
File: src/markets/perp/PerpOrderV3.sol

4: import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

6: import {IPredyPool} from "../../interfaces/IPredyPool.sol";

7: import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrderV3.sol)

```solidity
File: src/settlements/UniswapSettlement.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

6: import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

7: import {IQuoterV2} from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

8: import "../interfaces/ISettlement.sol";

54:             ERC20(quoteToken).safeTransfer(msg.sender, amountInMaximum - amountIn);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/settlements/UniswapSettlement.sol)

```solidity
File: src/tokenization/SupplyToken.sol

4: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

5: import {ISupplyToken} from "../interfaces/ISupplyToken.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

```solidity
File: src/types/GlobalData.sol

4: import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";

5: import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

6: import {ERC20} from "@solmate/src/tokens/ERC20.sol";

7: import "../interfaces/IPredyPool.sol";

8: import {IHooks} from "../interfaces/IHooks.sol";

9: import "../libraries/DataType.sol";

10: import "./LockData.sol";

111:         paid = reserveAfter.toInt256() - reservesBefore.toInt256();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

```solidity
File: src/types/LockData.sol

4: import "../interfaces/IPredyPool.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/LockData.sol)

### <a name="GAS-5"></a>[GAS-5] Use Custom Errors instead of Revert Strings to save Gas
Custom errors are available from solidity version 0.8.4. Custom errors save [**~50 gas**](https://gist.github.com/IllIllI000/ad1bd0d29a0101b25e57c293b4b0c746) each time they're hit by [avoiding having to allocate and store the revert string](https://blog.soliditylang.org/2021/04/21/custom-errors/#errors-in-depth). Not defining the strings also save deployment gas

Additionally, custom errors can be used inside and outside of contracts (including interfaces and libraries).

Source: <https://blog.soliditylang.org/2021/04/21/custom-errors/>:

> Starting from [Solidity v0.8.4](https://github.com/ethereum/solidity/releases/tag/v0.8.4), there is a convenient and gas-efficient way to explain to users why an operation failed through the use of custom errors. Until now, you could already use strings to give more information about failures (e.g., `revert("Insufficient funds.");`), but they are rather expensive, especially when it comes to deploy cost, and it is difficult to use dynamic information in them.

Consider replacing **all revert strings** with custom errors in the solution, and particularly those that have multiple occurrences:

*Instances (22)*:
```solidity
File: src/PredyPool.sol

182:         require(amount > 0, "AZ");

204:         require(amount > 0, "AZ");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/PriceFeed.sol

50:         require(basePrice.expo == -8, "INVALID_EXP");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/libraries/ScaledAsset.sol

55:         require(_supplyTokenAmount > 0, "S3");

67:         require(getAvailableCollateralValue(tokenState) >= finalWithdrawAmount, "S0");

85:             require(userStatus.lastFeeGrowth == tokenStatus.assetGrowth, "S2");

87:             require(userStatus.lastFeeGrowth == tokenStatus.debtGrowth, "S2");

108:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-closeAmount), "S0");

118:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-openAmount), "S0");

160:         require(accountState.positionAmount >= 0, "S1");

175:         require(accountState.positionAmount <= 0, "S1");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/UniHelper.sol

84:         revert("e/empty-error");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

60:         require(pairId < Constants.MAX_PAIRS, "MAXP");

76:         require(uniswapPool.token0() == stableTokenAddress || uniswapPool.token1() == stableTokenAddress, "C3");

153:         require(_pairs[_pairId].id == 0, "AAA");

206:         require(_fee <= 20, "FEE");

210:         require(_poolOwner != address(0), "ADDZ");

214:         require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

216:         require(_assetRiskParams.rangeSize > 0 && _assetRiskParams.rebalanceThreshold > 0, "C0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

45:         require(closeRatio > 0 && closeRatio <= 1e18, "ICR");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

64:         require(_amount > 0, "AZ");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/tokenization/SupplyToken.sol

11:         require(_controller == msg.sender, "ST0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

### <a name="GAS-6"></a>[GAS-6] Avoid contract existence checks by using low level calls
Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (4)*:
```solidity
File: src/libraries/logic/SupplyLogic.sol

86:             _pool.tokenStatus.removeAsset(ERC20(supplyTokenAddress).balanceOf(msg.sender), _amount);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/types/GlobalData.sol

40:         globalData.lockData.quoteReserve = ERC20(globalData.pairs[pairId].quotePool.token).balanceOf(address(this));

41:         globalData.lockData.baseReserve = ERC20(globalData.pairs[pairId].basePool.token).balanceOf(address(this));

103:         uint256 reserveAfter = ERC20(currency).balanceOf(address(this));

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

### <a name="GAS-7"></a>[GAS-7] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (19)*:
```solidity
File: src/PredyPool.sol

97:     function setOperator(address newOperator) external onlyOperator {

109:     function registerPair(AddPairLogic.AddPairParams memory addPairParam) external onlyOperator returns (uint256) {

147:     function updateFeeRatio(uint256 pairId, uint8 feeRatio) external onlyPoolOwner(pairId) {

157:     function updatePoolOwner(uint256 pairId, address poolOwner) external onlyPoolOwner(pairId) {

167:     function updatePriceOracle(uint256 pairId, address priceFeed) external onlyPoolOwner(pairId) {

177:     function withdrawProtocolRevenue(uint256 pairId, bool isQuoteToken) external onlyOperator {

199:     function withdrawCreatorRevenue(uint256 pairId, bool isQuoteToken) external onlyPoolOwner(pairId) {

286:     function updateRecepient(uint256 vaultId, address recipient) external onlyVaultOwner(vaultId) {

300:     function allowTrader(uint256 pairId, address trader, bool enabled) external onlyPoolOwner(pairId) {

329:     function take(bool isQuoteAsset, address to, uint256 amount) external onlyByLocker {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

20:     function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarket.sol

84:     function updateWhitelistFiller(address newWhitelistFiller) external onlyOwner {

92:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

128:     function updateWhitelistFiller(address newWhitelistFiller) external onlyFiller {

132:     function updateQuoter(address newQuoter) external onlyFiller {

140:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyFiller {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

392:     function removePosition(uint256 positionId) external onlyFiller {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/tokenization/SupplyToken.sol

21:     function mint(address account, uint256 amount) external virtual override onlyController {

25:     function burn(address account, uint256 amount) external virtual override onlyController {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

### <a name="GAS-8"></a>[GAS-8] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)
Pre-increments and pre-decrements are cheaper.

For a `uint256 i` variable, the following is true with the Optimizer enabled at 10k:

**Increment:**

- `i += 1` is the most expensive form
- `i++` costs 6 gas less than `i += 1`
- `++i` costs 5 gas less than `i++` (11 gas less than `i += 1`)

**Decrement:**

- `i -= 1` is the most expensive form
- `i--` costs 11 gas less than `i -= 1`
- `--i` costs 5 gas less than `i--` (16 gas less than `i -= 1`)

Note that post-increments (or post-decrements) return the old value before incrementing or decrementing, hence the name *post-increment*:

```solidity
uint i = 1;  
uint j = 2;
require(j == i++, "This will be false as i is incremented after the comparison");
```
  
However, pre-increments (or pre-decrements) return the new value:
  
```solidity
uint i = 1;  
uint j = 2;
require(j == ++i, "This will be true as i is incremented before the comparison");
```

In the pre-increment case, the compiler has to create a temporary variable (when used) for returning `1` instead of `2`.

Consider using pre-increments and pre-decrements where they are relevant (meaning: not where post-increments/decrements logic are relevant).

*Saves 5 gas per instance*

*Instances (5)*:
```solidity
File: src/libraries/Perp.sol

818:         sqrtPerpStatus.numRebalance++;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/VaultLib.sol

42:             globalData.vaultCount++;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/VaultLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

91:         _global.pairsCount++;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/markets/gamma/ArrayLib.sol

23:         for (uint256 i = 0; i < items.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

366:         for (uint64 i = 0; i < userPositionIDs.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

### <a name="GAS-9"></a>[GAS-9] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (2)*:
```solidity
File: src/libraries/SlippageLib.sol

13:     uint256 public constant MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 100747209;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/math/Bps.sol

5:     uint32 public constant ONE = 1e6;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Bps.sol)

### <a name="GAS-10"></a>[GAS-10] Use shift right/left instead of division/multiplication if possible
While the `DIV` / `MUL` opcode uses 5 gas, the `SHR` / `SHL` opcode only uses 3 gas. Furthermore, beware that Solidity's division operation also includes a division-by-0 prevention which is bypassed using shifting. Eventually, overflow checks are never performed for shift operations as they are done for arithmetic operations. Instead, the result is always truncated, so the calculation can be unchecked in Solidity version `0.8+`
- Use `>> 1` instead of `/ 2`
- Use `>> 2` instead of `/ 4`
- Use `<< 3` instead of `* 8`
- ...
- Use `>> 5` instead of `/ 2^5 == / 32`
- Use `<< 6` instead of `* 2^6 == * 64`

TL;DR:
- Shifting left by N is like multiplying by 2^N (Each bits to the left is an increased power of 2)
- Shifting right by N is like dividing by 2^N (Each bits to the right is a decreased power of 2)

*Saves around 2 gas + 20 for unchecked per instance*

*Instances (5)*:
```solidity
File: src/libraries/ApplyInterestLib.sol

71:         poolStatus.accumulatedProtocolRevenue += totalProtocolFee / 2;

72:         poolStatus.accumulatedCreatorRevenue += totalProtocolFee / 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/Reallocation.sol

51:         int24 previousCenterTick = (sqrtAssetStatus.tickLower + sqrtAssetStatus.tickUpper) / 2;

67:                     upper = lower + _assetStatusUnderlying.riskParams.rangeSize * 2;

80:                     lower = upper - _assetStatusUnderlying.riskParams.rangeSize * 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

### <a name="GAS-11"></a>[GAS-11] Splitting require() statements that use && saves gas

*Instances (7)*:
```solidity
File: src/PriceFeed.sol

52:         require(quoteAnswer > 0 && basePrice.price > 0);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseMarket.sol

105:         require(_quoteTokenMap[pairId] != address(0) && entryTokenAddress == _quoteTokenMap[pairId]);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

153:         require(_quoteTokenMap[pairId] != address(0) && entryTokenAddress == _quoteTokenMap[pairId]);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

214:         require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

216:         require(_assetRiskParams.rangeSize > 0 && _assetRiskParams.rebalanceThreshold > 0, "C0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

45:         require(closeRatio > 0 && closeRatio <= 1e18, "ICR");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

203:         require(-1e6 < modifyInfo.maximaDeviation && modifyInfo.maximaDeviation < 1e6);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

### <a name="GAS-12"></a>[GAS-12] `uint256` to `bool` `mapping`: Utilizing Bitmaps to dramatically save on Gas
https://soliditydeveloper.com/bitmaps

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol

- [BitMaps.sol#L5-L16](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol#L5-L16):

```solidity
/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, provided the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 *
 * BitMaps pack 256 booleans across each bit of a single 256-bit slot of `uint256` type.
 * Hence booleans corresponding to 256 _sequential_ indices would only consume a single slot,
 * unlike the regular `bool` which would consume an entire slot for a single value.
 *
 * This results in gas savings in two ways:
 *
 * - Setting a zero value to non-zero only once every 256 times
 * - Accessing the same warm slot for every 256 _sequential_ indices
 */
```

*Instances (1)*:
```solidity
File: src/PredyPool.sol

40:     mapping(address trader => mapping(uint256 pairId => bool)) public allowedTraders;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

### <a name="GAS-13"></a>[GAS-13] Increments/decrements can be unchecked in for-loops
In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (2)*:
```solidity
File: src/markets/gamma/ArrayLib.sol

23:         for (uint256 i = 0; i < items.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

366:         for (uint64 i = 0; i < userPositionIDs.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

### <a name="GAS-14"></a>[GAS-14] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (57)*:
```solidity
File: src/PredyPool.sol

84:         if (amount0 > 0) {

87:         if (amount1 > 0) {

182:         require(amount > 0, "AZ");

186:         if (amount > 0) {

204:         require(amount > 0, "AZ");

208:         if (amount > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/PriceFeed.sol

52:         require(quoteAnswer > 0 && basePrice.price > 0);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

83:             baseAmountDelta > 0 ? minQuoteAmount : maxQuoteAmount,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

55:         if (settlementParams.fee > 0) {

67:         if (baseAmountDelta > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/ApplyInterestLib.sol

45:         if (interestRateQuote > 0 || interestRateBase > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/Perp.sol

165:         if (_sqrtAssetStatus.lastRebalanceTotalSquartAmount > 0) {

443:         if (_tradeSqrtAmount > 0) {

551:         if (closeAmount > 0) {

560:         if (openAmount > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PerpFee.sol

73:         if (sqrtPerp.amount > 0) {

101:         if (sqrtPerp.amount > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/PositionCalculator.sol

210:         if (_positionParams.amountSqrt < 0 && _positionParams.amountBase > 0) {

245:         if (squartPosition > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/Reallocation.sol

55:         if (availableAmount > 0) {

110:         require(tickSpacing > 0);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/ScaledAsset.sol

55:         require(_supplyTokenAmount > 0, "S3");

84:         if (userStatus.positionAmount > 0) {

104:         if (closeAmount > 0) {

113:         if (openAmount > 0) {

135:         if (_userStatus.positionAmount > 0) {

148:         if (_userStatus.positionAmount > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/SlippageLib.sol

33:         if (tradeResult.averagePrice > 0) {

46:             maxAcceptableSqrtPriceRange > 0

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/UniHelper.sol

78:         if (errMsg.length > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

216:         require(_assetRiskParams.rangeSize > 0 && _assetRiskParams.rebalanceThreshold > 0, "C0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

45:         require(closeRatio > 0 && closeRatio <= 1e18, "ICR");

92:             if (remainingMargin > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

68:                 if (exceedsQuote > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

64:         require(_amount > 0, "AZ");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/libraries/math/Math.sol

27:         } else if (x > 0) {

37:         } else if (x > 0) {

47:         } else if (x > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Math.sol)

```solidity
File: src/markets/gamma/GammaOrder.sol

135:         uint256 amount = gammaOrder.marginAmount > 0 ? uint256(gammaOrder.marginAmount) : 0;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaOrder.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

117:                 if (marginAmountUpdate > 0) {

178:         if (tradeResult.minMargin > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

65:             userPosition.hedgeInterval > 0

122:         if (lowerThreshold > 0 && lowerThreshold >= sqrtIndexPrice) {

130:         if (upperThreshold > 0 && upperThreshold <= sqrtIndexPrice) {

197:         if (0 < modifyInfo.hedgeInterval && 10 minutes > modifyInfo.hedgeInterval) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

54:             if (currentPositionAmount > 0) {

65:                 if (tradeAmount > 0) {

97:         } else if (limitPrice > 0 && stopPrice > 0) {

105:         } else if (limitPrice > 0) {

110:         } else if (stopPrice > 0) {

127:         if (tradeAmount > 0 && limitPrice < tradePrice) {

155:         if (tradeAmount > 0) {

200:             if (tradeAmount > 0 && decayedPrice < tradePrice) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

119:             if (marginAmountUpdate > 0) {

125:             if (marginAmountUpdate > 0) {

200:         if (tradeResult.minMargin > 0) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/markets/perp/PerpOrder.sol

74:         uint256 amount = perpOrder.marginAmount > 0 ? uint256(perpOrder.marginAmount) : 0;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrder.sol)


## Non Critical Issues


| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Replace `abi.encodeWithSignature` and `abi.encodeWithSelector` with `abi.encodeCall` which keeps the code typo/type safe | 3 |
| [NC-2](#NC-2) | Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked` | 10 |
| [NC-3](#NC-3) | `constant`s should be defined rather than using magic numbers | 18 |
| [NC-4](#NC-4) | Control structures do not follow the Solidity Style Guide | 98 |
| [NC-5](#NC-5) | Default Visibility for constants | 1 |
| [NC-6](#NC-6) | Functions should not be longer than 50 lines | 216 |
| [NC-7](#NC-7) | Change uint to uint256 | 11 |
| [NC-8](#NC-8) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 14 |
| [NC-9](#NC-9) | Consider using named mappings | 13 |
| [NC-10](#NC-10) | Take advantage of Custom Error's return value property | 54 |
| [NC-11](#NC-11) | Avoid the use of sensitive terms | 28 |
| [NC-12](#NC-12) | Some require descriptions are not clear | 18 |
| [NC-13](#NC-13) | Use Underscores for Number Literals (add an underscore every 3 digits) | 14 |
| [NC-14](#NC-14) | Constants should be defined rather than using magic numbers | 16 |
| [NC-15](#NC-15) | Variables need not be initialized to zero | 5 |
### <a name="NC-1"></a>[NC-1] Replace `abi.encodeWithSignature` and `abi.encodeWithSelector` with `abi.encodeCall` which keeps the code typo/type safe
When using `abi.encodeWithSignature`, it is possible to include a typo for the correct function signature.
When using `abi.encodeWithSignature` or `abi.encodeWithSelector`, it is also possible to provide parameters that are not of the correct type for the function.

To avoid these pitfalls, it would be best to use [`abi.encodeCall`](https://solidity-by-example.org/abi-encode/) instead.

*Instances (3)*:
```solidity
File: src/libraries/UniHelper.sol

42:             address(uniswapPool).staticcall(abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos));

45:             if (keccak256(data) != keccak256(abi.encodeWithSignature("Error(string)", "OLD"))) {

61:                 abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

### <a name="NC-2"></a>[NC-2] Use `string.concat()` or `bytes.concat()` instead of `abi.encodePacked`
Solidity version 0.8.4 introduces `bytes.concat()` (vs `abi.encodePacked(<bytes>,<bytes>)`)

Solidity version 0.8.12 introduces `string.concat()` (vs `abi.encodePacked(<str>,<str>), which catches concatenation errors (in the event of a `bytes` data mixed in the concatenation)`)

*Instances (10)*:
```solidity
File: src/markets/gamma/GammaOrder.sol

24:     bytes internal constant GAMMA_MODIFY_INFO_TYPE = abi.encodePacked(

81:     bytes internal constant GAMMA_ORDER_TYPE = abi.encodePacked(

98:         abi.encodePacked(GAMMA_ORDER_TYPE, GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE, OrderInfoLib.ORDER_INFO_TYPE);

103:         abi.encodePacked(

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaOrder.sol)

```solidity
File: src/markets/perp/PerpOrder.sol

27:     bytes internal constant PERP_ORDER_TYPE = abi.encodePacked(

43:     bytes internal constant ORDER_TYPE = abi.encodePacked(PERP_ORDER_TYPE, OrderInfoLib.ORDER_INFO_TYPE);

48:         abi.encodePacked("PerpOrder witness)", OrderInfoLib.ORDER_INFO_TYPE, PERP_ORDER_TYPE, TOKEN_PERMISSIONS_TYPE)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrder.sol)

```solidity
File: src/markets/perp/PerpOrderV3.sol

28:     bytes internal constant PERP_ORDER_V3_TYPE = abi.encodePacked(

45:     bytes internal constant ORDER_V3_TYPE = abi.encodePacked(PERP_ORDER_V3_TYPE, OrderInfoLib.ORDER_INFO_TYPE);

50:         abi.encodePacked(

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrderV3.sol)

### <a name="NC-3"></a>[NC-3] `constant`s should be defined rather than using magic numbers
Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39) can benefit from using readable constants instead of hex/numeric literals

*Instances (18)*:
```solidity
File: src/libraries/ApplyInterestLib.sol

71:         poolStatus.accumulatedProtocolRevenue += totalProtocolFee / 2;

72:         poolStatus.accumulatedCreatorRevenue += totalProtocolFee / 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/Perp.sol

399:             f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

402:             f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

405:         _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);

406:         _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

590:         uint256 buffer = Math.max(_assetStatus.totalAmount / 50, Constants.MIN_LIQUIDITY);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/Reallocation.sol

51:         int24 previousCenterTick = (sqrtAssetStatus.tickLower + sqrtAssetStatus.tickUpper) / 2;

67:                     upper = lower + _assetStatusUnderlying.riskParams.rangeSize * 2;

80:                     lower = upper - _assetStatusUnderlying.riskParams.rangeSize * 2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/ScaledAsset.sol

197:             100

205:             100 - _reserveFactor,

206:             100

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

206:         require(_fee <= 20, "FEE");

214:         require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

222:                 && _irmParams.slope2 <= 10 * 1e18,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

197:         if (0 < modifyInfo.hedgeInterval && 10 minutes > modifyInfo.hedgeInterval) {

202:         require(modifyInfo.maxSlippageTolerance <= 2 * Bps.ONE);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

### <a name="NC-4"></a>[NC-4] Control structures do not follow the Solidity Style Guide
See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (98)*:
```solidity
File: src/PredyPool.sol

48:         if (operator != msg.sender) revert CallerIsNotOperator();

54:         if (msg.sender != locker) revert LockedBy(locker);

59:         if (globalData.pairs[pairId].poolOwner != msg.sender) revert CallerIsNotPoolCreator();

64:         if (globalData.vaults[vaultId].owner != msg.sender) revert CallerIsNotVaultOwner();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/PriceFeed.sol

12:     event PriceFeedCreated(address quotePrice, bytes32 priceId, uint256 decimalsDiff, address priceFeed);

19:         PriceFeed priceFeed = new PriceFeed(quotePrice, _pyth, priceId, decimalsDiff);

21:         emit PriceFeedCreated(quotePrice, priceId, decimalsDiff, address(priceFeed));

32:     uint256 private immutable _decimalsDiff;

41:         _decimalsDiff = decimalsDiff;

55:         price = price * Constants.Q96 / _decimalsDiff;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseHookCallback.sol

17:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallback.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

16:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarket.sol

7: import "../interfaces/IFillerMarket.sol";

40:     function reallocate(uint256 pairId, IFillerMarket.SettlementParams memory settlementParams)

50:         IFillerMarket.SettlementParams memory settlementParams

55:     function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams)

63:     function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams, address filler)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

8: import "../interfaces/IFillerMarket.sol";

32:         if (msg.sender != whitelistFiller) revert CallerIsNotFiller();

89:     function reallocate(uint256 pairId, IFillerMarket.SettlementParamsV3 memory settlementParams)

99:         IFillerMarket.SettlementParamsV3 memory settlementParams

105:     function _getSettlementDataFromV3(IFillerMarket.SettlementParamsV3 memory settlementParams, address filler)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

10: import {IFillerMarket} from "../interfaces/IFillerMarket.sol";

33:         if (

36:             revert IFillerMarket.SettlementContractIsNotWhitelisted();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/Perp.sol

209:         if (

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PerpFee.sol

70:         uint256 growthDiff0;

71:         uint256 growthDiff1;

74:             growthDiff0 = baseAssetStatus.sqrtAssetStatus.fee0Growth - sqrtPerp.entryTradeFee0;

75:             growthDiff1 = baseAssetStatus.sqrtAssetStatus.fee1Growth - sqrtPerp.entryTradeFee1;

77:             growthDiff0 = baseAssetStatus.sqrtAssetStatus.borrowPremium0Growth - sqrtPerp.entryTradeFee0;

78:             growthDiff1 = baseAssetStatus.sqrtAssetStatus.borrowPremium1Growth - sqrtPerp.entryTradeFee1;

83:         int256 fee0 = Math.fullMulDivDownInt256(sqrtPerp.amount, growthDiff0, Constants.Q128);

84:         int256 fee1 = Math.fullMulDivDownInt256(sqrtPerp.amount, growthDiff1, Constants.Q128);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/SlippageLib.sol

45:         if (

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

69:         if (

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/math/LPMath.sol

42:         if (sqrtRatioA > sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

80:         if (sqrtRatioA < sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/LPMath.sol)

```solidity
File: src/markets/gamma/GammaOrder.sol

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

24:     bytes internal constant GAMMA_MODIFY_INFO_TYPE = abi.encodePacked(

25:         "GammaModifyInfo(",

39:     bytes32 internal constant GAMMA_MODIFY_INFO_TYPE_HASH = keccak256(GAMMA_MODIFY_INFO_TYPE);

46:                 GAMMA_MODIFY_INFO_TYPE_HASH,

74:     GammaModifyInfo modifyInfo;

93:         "GammaModifyInfo modifyInfo)"

98:         abi.encodePacked(GAMMA_ORDER_TYPE, GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE, OrderInfoLib.ORDER_INFO_TYPE);

105:             GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE,

129:                 GammaModifyInfoLib.hash(order.modifyInfo)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaOrder.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

9: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

17: import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";

32:     error PositionHasDifferentPairId();

65:     event GammaPositionModified(address indexed trader, uint256 pairId, uint256 positionId, GammaModifyInfo modifyInfo);

141:         IFillerMarket.SettlementParamsV3 memory settlementParams

160:         _verifyOrder(resolvedOrder);

189:         _saveUserPosition(userPosition, gammaOrder.modifyInfo);

218:         _verifyOrder(resolvedOrder);

224:         _saveUserPosition(userPosition, gammaOrder.modifyInfo);

430:             revert PositionHasDifferentPairId();

436:     function _saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)

440:             emit GammaPositionModified(userPosition.owner, userPosition.pairId, userPosition.vaultId, modifyInfo);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketL2.sol

6: import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";

19:     bytes32 modifyParam;

47:         GammaModifyInfo memory modifyInfo = L2GammaDecoder.decodeGammaModifyInfo(

48:             order.modifyParam, order.lowerLimit, order.upperLimit, order.maximaDeviation

65:                 modifyInfo

74:         GammaModifyInfo memory modifyInfo =

75:             L2GammaDecoder.decodeGammaModifyInfo(order.param, order.lowerLimit, order.upperLimit, order.maximaDeviation);

79:         _modifyAutoHedgeAndClose(

91:                 modifyInfo

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketL2.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

9: import {GammaModifyInfo} from "./GammaOrder.sol";

64:         if (

189:     function saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)

201:         require(modifyInfo.maxSlippageTolerance >= modifyInfo.minSlippageTolerance);

202:         require(modifyInfo.maxSlippageTolerance <= 2 * Bps.ONE);

203:         require(-1e6 < modifyInfo.maximaDeviation && modifyInfo.maximaDeviation < 1e6);

206:         userPosition.expiration = modifyInfo.expiration;

207:         userPosition.lowerLimit = modifyInfo.lowerLimit;

208:         userPosition.upperLimit = modifyInfo.upperLimit;

211:         userPosition.maximaDeviation = modifyInfo.maximaDeviation;

212:         userPosition.hedgeInterval = modifyInfo.hedgeInterval;

213:         userPosition.sqrtPriceTrigger = modifyInfo.sqrtPriceTrigger;

214:         userPosition.auctionParams.minSlippageTolerance = modifyInfo.minSlippageTolerance;

215:         userPosition.auctionParams.maxSlippageTolerance = modifyInfo.maxSlippageTolerance;

216:         userPosition.auctionParams.auctionPeriod = modifyInfo.auctionPeriod;

217:         userPosition.auctionParams.auctionRange = modifyInfo.auctionRange;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketWrapper.sol

6: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketWrapper.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

4: import {GammaModifyInfo} from "./GammaOrder.sol";

7:     function decodeGammaModifyInfo(bytes32 args, uint256 lowerLimit, uint256 upperLimit, int64 maximaDeviation)

10:         returns (GammaModifyInfo memory)

21:         ) = decodeGammaModifyParam(args);

23:         return GammaModifyInfo(

51:     function decodeGammaModifyParam(bytes32 args)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

99:             if (

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

123:             _verifyOrderV3(callbackData.resolvedOrder, cost);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/markets/perp/PerpOrder.sol

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrder.sol)

```solidity
File: src/markets/perp/PerpOrderV3.sol

5: import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrderV3.sol)

```solidity
File: src/types/GlobalData.sol

27:         if (vaultId <= 0 || globalData.vaultCount <= vaultId) revert IPredyPool.InvalidPairId();

31:         if (pairId <= 0 || globalData.pairsCount <= pairId) revert IPredyPool.InvalidPairId();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

### <a name="NC-5"></a>[NC-5] Default Visibility for constants
Some constants are using the default visibility. For readability, consider explicitly declaring them as `internal`.

*Instances (1)*:
```solidity
File: src/libraries/logic/LiquidationLogic.sol

27:     uint256 constant _MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 101488915;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

### <a name="NC-6"></a>[NC-6] Functions should not be longer than 50 lines
Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability 

*Instances (216)*:
```solidity
File: src/PredyPool.sol

70:     function initialize(address uniswapFactory) public initializer {

78:     function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata) external override {

97:     function setOperator(address newOperator) external onlyOperator {

109:     function registerPair(AddPairLogic.AddPairParams memory addPairParam) external onlyOperator returns (uint256) {

119:     function updateAssetRiskParams(uint256 pairId, Perp.AssetRiskParams memory riskParams)

147:     function updateFeeRatio(uint256 pairId, uint8 feeRatio) external onlyPoolOwner(pairId) {

157:     function updatePoolOwner(uint256 pairId, address poolOwner) external onlyPoolOwner(pairId) {

167:     function updatePriceOracle(uint256 pairId, address priceFeed) external onlyPoolOwner(pairId) {

177:     function withdrawProtocolRevenue(uint256 pairId, bool isQuoteToken) external onlyOperator {

199:     function withdrawCreatorRevenue(uint256 pairId, bool isQuoteToken) external onlyPoolOwner(pairId) {

222:     function supply(uint256 pairId, bool isQuoteAsset, uint256 supplyAmount)

237:     function withdraw(uint256 pairId, bool isQuoteAsset, uint256 withdrawAmount)

251:     function reallocate(uint256 pairId, bytes memory settlementData)

265:     function trade(TradeParams memory tradeParams, bytes memory settlementData)

286:     function updateRecepient(uint256 vaultId, address recipient) external onlyVaultOwner(vaultId) {

300:     function allowTrader(uint256 pairId, address trader, bool enabled) external onlyPoolOwner(pairId) {

313:     function execLiquidationCall(uint256 vaultId, uint256 closeRatio, bytes memory settlementData)

329:     function take(bool isQuoteAsset, address to, uint256 amount) external onlyByLocker {

337:     function createVault(uint256 pairId) external returns (uint256) {

344:     function getSqrtPrice(uint256 pairId) external view returns (uint160) {

352:     function getSqrtIndexPrice(uint256 pairId) external view returns (uint256) {

357:     function getPairStatus(uint256 pairId) external view returns (DataType.PairStatus memory) {

364:     function getVault(uint256 vaultId) external view returns (DataType.Vault memory) {

370:     function revertPairStatus(uint256 pairId) external {

376:     function revertVaultStatus(uint256 vaultId) external {

380:     function _getAssetStatusPool(uint256 pairId, bool isQuoteToken)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/PriceFeed.sol

18:     function createPriceFeed(address quotePrice, bytes32 priceId, uint256 decimalsDiff) external returns (address) {

45:     function getSqrtPrice() external view returns (uint256 sqrtPrice) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

20:     function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarket.sol

40:     function reallocate(uint256 pairId, IFillerMarket.SettlementParams memory settlementParams)

55:     function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams)

63:     function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams, address filler)

84:     function updateWhitelistFiller(address newWhitelistFiller) external onlyOwner {

92:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyOwner {

97:     function updateQuoteTokenMap(uint256 pairId) external {

104:     function _validateQuoteTokenAddress(uint256 pairId, address entryTokenAddress) internal view {

108:     function _getQuoteTokenAddress(uint256 pairId) internal view returns (address) {

114:     function _revertTradeResult(IPredyPool.TradeResult memory tradeResult) internal pure {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

38:     function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)

61:     function decodeParamsV3(bytes memory settlementData, int256 baseAmountDelta)

89:     function reallocate(uint256 pairId, IFillerMarket.SettlementParamsV3 memory settlementParams)

105:     function _getSettlementDataFromV3(IFillerMarket.SettlementParamsV3 memory settlementParams, address filler)

128:     function updateWhitelistFiller(address newWhitelistFiller) external onlyFiller {

132:     function updateQuoter(address newQuoter) external onlyFiller {

140:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyFiller {

145:     function updateQuoteTokenMap(uint256 pairId) external {

152:     function _validateQuoteTokenAddress(uint256 pairId, address entryTokenAddress) internal view {

156:     function _getQuoteTokenAddress(uint256 pairId) internal view returns (address) {

162:     function _revertTradeResult(IPredyPool.TradeResult memory tradeResult) internal pure {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

25:     function decodeParams(bytes memory settlementData) internal pure returns (SettlementParams memory) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/ApplyInterestLib.sol

26:     function applyInterestForToken(mapping(uint256 => DataType.PairStatus) storage pairs, uint256 pairId) internal {

50:     function applyInterestForPoolStatus(Perp.AssetPoolStatus storage poolStatus, uint256 lastUpdateTimestamp, uint8 fee)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/InterestRateModel.sol

18:     function calculateInterestRate(IRMParams memory irmParams, uint256 utilizationRatio)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/InterestRateModel.sol)

```solidity
File: src/libraries/PairLib.sol

5:     function getRebalanceCacheId(uint256 pairId, uint64 rebalanceId) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PairLib.sol)

```solidity
File: src/libraries/Perp.sol

119:     function createAssetStatus(address uniswapPool, int24 tickLower, int24 tickUpper)

145:     function createPerpUserStatus(uint64 _pairId) internal pure returns (UserStatus memory) {

345:     function settleUserBalance(DataType.PairStatus storage _pairStatus, UserStatus storage _userStatus) internal {

373:     function updateFeeAndPremiumGrowth(uint256 _pairId, SqrtPerpAssetStatus storage _assetStatus) internal {

414:     function saveLastFeeGrowth(SqrtPerpAssetStatus storage _assetStatus) internal {

585:     function getAvailableSqrtAmount(SqrtPerpAssetStatus memory _assetStatus, bool _isWithdraw)

604:     function getUtilizationRatio(SqrtPerpAssetStatus memory _assetStatus) internal pure returns (uint256) {

673:     function calculateEntry(int256 _positionAmount, int256 _entryValue, int256 _tradeAmount, int256 _valueUpdate)

707:     function increase(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)

719:     function decrease(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)

815:     function finalizeReallocation(SqrtPerpAssetStatus storage sqrtPerpStatus) internal {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PerpFee.sol

65:     function computePremium(DataType.PairStatus memory baseAssetStatus, Perp.SqrtPositionStatus memory sqrtPerp)

95:     function settlePremium(DataType.PairStatus memory baseAssetStatus, Perp.SqrtPositionStatus storage sqrtPerp)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/PositionCalculator.sol

102:     function calculateRequiredCollateralWithDebt(uint128 debtRiskRatio) internal pure returns (uint256) {

135:     function getHasPosition(DataType.Vault memory _vault) internal pure returns (bool hasPosition) {

141:     function getSqrtIndexPrice(DataType.PairStatus memory pairStatus) internal view returns (uint256 sqrtPriceX96) {

151:     function getPositionWithFeeAmount(Perp.UserStatus memory perpUserStatus, DataType.FeeAmount memory feeAmount)

163:     function getPosition(Perp.UserStatus memory _perpUserStatus)

175:     function getHasPositionFlag(PositionParams memory _positionParams) internal pure returns (bool) {

186:     function calculateMinValue(uint256 _sqrtPrice, PositionParams memory _positionParams, uint256 _riskRatio)

231:     function calculateValue(uint256 _sqrtPrice, PositionParams memory _positionParams) internal pure returns (int256) {

238:     function calculateSquartDebtValue(uint256 _sqrtPrice, PositionParams memory positionParams)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/PremiumCurveModel.sol

14:     function calculatePremiumCurve(uint256 utilization) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PremiumCurveModel.sol)

```solidity
File: src/libraries/Reallocation.sol

18:     function getNewRange(DataType.PairStatus memory _assetStatusUnderlying, int24 currentTick)

92:     function isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus) internal view returns (bool) {

98:     function _isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus, int24 currentTick)

109:     function calculateUsableTick(int24 _tick, int24 tickSpacing) internal pure returns (int24 result) {

165:     function calculateAmount1ForLiquidity(uint160 sqrtRatioA, uint256 available, uint256 liquidityAmount)

179:     function calculateAmount0ForLiquidity(uint160 sqrtRatioB, uint256 available, uint256 liquidityAmount)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/ScaledAsset.sol

29:     function createAssetStatus() internal pure returns (AssetStatus memory) {

33:     function createUserStatus() internal pure returns (UserStatus memory) {

37:     function addAsset(AssetStatus storage tokenState, uint256 _amount) internal returns (uint256 claimAmount) {

47:     function removeAsset(AssetStatus storage tokenState, uint256 _supplyTokenAmount, uint256 _amount)

72:     function isSameSign(int256 a, int256 b) internal pure returns (bool) {

130:     function computeUserFee(ScaledAsset.AssetStatus memory _assetStatus, ScaledAsset.UserStatus memory _userStatus)

142:     function settleUserFee(ScaledAsset.AssetStatus memory _assetStatus, ScaledAsset.UserStatus storage _userStatus)

155:     function getAssetFee(AssetStatus memory tokenState, UserStatus memory accountState)

170:     function getDebtFee(AssetStatus memory tokenState, UserStatus memory accountState)

186:     function updateScaler(AssetStatus storage tokenState, uint256 _interestRate, uint8 _reserveFactor)

217:     function getTotalCollateralValue(AssetStatus memory tokenState) internal pure returns (uint256) {

222:     function getTotalDebtValue(AssetStatus memory tokenState) internal pure returns (uint256) {

226:     function getAvailableCollateralValue(AssetStatus memory tokenState) internal pure returns (uint256) {

230:     function getUtilizationRatio(AssetStatus memory tokenState) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/Trade.sol

112:     function getSqrtPrice(address uniswapPoolAddress, bool isQuoteZero) internal view returns (uint256 sqrtPriceX96) {

116:     function calculateStableAmount(uint256 currentSqrtPrice, uint256 baseAmount) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/UniHelper.sol

13:     function getSqrtPrice(address uniswapPoolAddress) internal view returns (uint160 sqrtPrice) {

20:     function getSqrtTWAP(address uniswapPoolAddress) internal view returns (uint160 sqrtTwapX96) {

27:     function convertSqrtPrice(uint160 sqrtPriceX96, bool isQuoteZero) internal pure returns (uint160) {

35:     function callUniswapObserve(IUniswapV3Pool uniswapPool, uint256 ago) internal view returns (uint160, uint256) {

77:     function revertBytes(bytes memory errMsg) internal pure {

87:     function getFeeGrowthInsideLast(address uniswapPoolAddress, int24 tickLower, int24 tickUpper)

99:     function getFeeGrowthInside(address uniswapPoolAddress, int24 tickLower, int24 tickUpper)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/VaultLib.sol

11:     function getVault(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId)

24:     function createOrGetVault(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId, uint256 pairId)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/VaultLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

44:     function initializeGlobalData(GlobalDataLibrary.GlobalData storage global, address uniswapFactory) external {

96:     function updateFeeRatio(DataType.PairStatus storage _pairStatus, uint8 _feeRatio) external {

104:     function updatePoolOwner(DataType.PairStatus storage _pairStatus, address _poolOwner) external {

112:     function updatePriceOracle(DataType.PairStatus storage _pairStatus, address _priceOracle) external {

118:     function updateAssetRiskParams(DataType.PairStatus storage _pairStatus, Perp.AssetRiskParams memory _riskParams)

192:     function deploySupplyToken(address _tokenAddress) internal returns (address) {

205:     function validateFeeRatio(uint8 _fee) internal pure {

209:     function validatePoolOwner(address _poolOwner) internal pure {

213:     function validateRiskParams(Perp.AssetRiskParams memory _assetRiskParams) internal pure {

219:     function validateIRMParams(InterestRateModel.IRMParams memory _irmParams) internal pure {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

159:     function calculateSlippageTolerance(int256 minMargin, int256 vaultValue, Perp.AssetRiskParams memory riskParams)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/ReaderLogic.sol

16:     function getPairStatus(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) external {

24:     function getVaultStatus(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId) external {

43:     function getPosition(DataType.Vault memory vault, DataType.FeeAmount memory feeAmount)

56:     function revertPairStatus(DataType.PairStatus memory pairStatus) internal pure {

64:     function revertVaultStatus(IPredyPool.VaultStatus memory vaultStatus) internal pure {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReaderLogic.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

27:     function reallocate(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId, bytes memory settlementData)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

22:     function supply(GlobalDataLibrary.GlobalData storage globalData, uint256 _pairId, uint256 _amount, bool _isStable)

46:     function receiveTokenAndMintBond(Perp.AssetPoolStatus storage _pool, uint256 _amount)

57:     function withdraw(GlobalDataLibrary.GlobalData storage globalData, uint256 _pairId, uint256 _amount, bool _isStable)

79:     function burnBondAndTransferToken(Perp.AssetPoolStatus storage _pool, uint256 _amount)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/libraries/math/Bps.sol

7:     function upper(uint256 price, uint256 bps) internal pure returns (uint256) {

11:     function lower(uint256 price, uint256 bps) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Bps.sol)

```solidity
File: src/libraries/math/LPMath.sol

10:     function calculateAmount0ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)

20:     function calculateAmount1ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)

108:     function calculateAmount0OffsetWithTick(int24 upper, uint256 liquidityAmount, bool isRoundUp)

119:     function calculateAmount0Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)

134:     function calculateAmount1OffsetWithTick(int24 lower, uint256 liquidityAmount, bool isRoundUp)

145:     function calculateAmount1Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/LPMath.sol)

```solidity
File: src/libraries/math/Math.sol

12:     function abs(int256 x) internal pure returns (uint256) {

16:     function max(uint256 a, uint256 b) internal pure returns (uint256) {

20:     function min(uint256 a, uint256 b) internal pure returns (uint256) {

24:     function fullMulDivInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {

34:     function fullMulDivDownInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {

44:     function mulDivDownInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {

54:     function addDelta(uint256 a, int256 b) internal pure returns (uint256) {

62:     function calSqrtPriceToPrice(uint256 sqrtPrice) internal pure returns (uint256 price) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Math.sol)

```solidity
File: src/libraries/orders/DecayLib.sol

8:     function decay(uint256 startPrice, uint256 endPrice, uint256 decayStartTime, uint256 decayEndTime)

16:     function decay2(uint256 startPrice, uint256 endPrice, uint256 decayStartTime, uint256 decayEndTime, uint256 value)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/DecayLib.sol)

```solidity
File: src/libraries/orders/OrderInfoLib.sol

18:     function hash(OrderInfo memory info) internal pure returns (bytes32) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/OrderInfoLib.sol)

```solidity
File: src/libraries/orders/Permit2Lib.sol

23:     function transferDetails(ResolvedOrder memory order, address to)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/Permit2Lib.sol)

```solidity
File: src/libraries/orders/ResolvedOrder.sol

23:     function validate(ResolvedOrder memory resolvedOrder) internal view {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/ResolvedOrder.sol)

```solidity
File: src/markets/L2Decoder.sol

5:     function decodeSpotOrderParams(bytes32 args1, bytes32 args2)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/L2Decoder.sol)

```solidity
File: src/markets/gamma/ArrayLib.sol

5:     function addItem(uint256[] storage items, uint256 item) internal {

9:     function removeItem(uint256[] storage items, uint256 item) internal {

15:     function removeItemByIndex(uint256[] storage items, uint256 index) internal {

20:     function getItemIndex(uint256[] memory items, uint256 item) internal pure returns (uint256) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaOrder.sol

43:     function hash(GammaModifyInfo memory info) internal pure returns (bytes32) {

115:     function hash(GammaOrder memory order) internal pure returns (bytes32) {

134:     function resolve(GammaOrder memory gammaOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaOrder.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

69:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

152:     function _executeTrade(GammaOrder memory gammaOrder, bytes memory sig, SettlementParamsV3 memory settlementParams)

211:     function _modifyAutoHedgeAndClose(GammaOrder memory gammaOrder, bytes memory sig) internal {

227:     function autoHedge(uint256 positionId, SettlementParamsV3 memory settlementParams)

274:     function autoClose(uint256 positionId, SettlementParamsV3 memory settlementParams)

315:     function quoteTrade(GammaOrder memory gammaOrder, SettlementParamsV3 memory settlementParams) external {

333:     function checkAutoHedgeAndClose(uint256 positionId)

361:     function getUserPositions(address owner) external returns (UserPositionResult[] memory) {

375:     function _getUserPosition(uint256 positionId) internal returns (UserPositionResult memory result) {

388:     function _addPositionIndex(address trader, uint256 newPositionId) internal {

392:     function removePosition(uint256 positionId) external onlyFiller {

402:     function _removePosition(uint256 positionId) internal {

408:     function _getOrInitPosition(uint256 positionId, bool isCreatedNew, address trader, uint64 pairId)

436:     function _saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)

444:     function _verifyOrder(ResolvedOrder memory order) internal {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketL2.sol

42:     function executeTradeL2(GammaOrderL2 memory order, bytes memory sig, SettlementParamsV3 memory settlementParams)

73:     function modifyAutoHedgeAndClose(GammaModifyOrderL2 memory order, bytes memory sig) external {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketL2.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

48:     function calculateDelta(uint256 _sqrtPrice, int64 maximaDeviation, int256 _sqrtAmount, int256 perpAmount)

59:     function validateHedgeCondition(GammaTradeMarketLib.UserPosition memory userPosition, uint256 sqrtIndexPrice)

106:     function validateCloseCondition(UserPosition memory userPosition, uint256 sqrtIndexPrice)

141:     function calculateSlippageTolerance(uint256 startTime, uint256 currentTime, AuctionParams memory auctionParams)

167:     function calculateSlippageToleranceByPrice(uint256 price1, uint256 price2, AuctionParams memory auctionParams)

189:     function saveUserPosition(GammaTradeMarketLib.UserPosition storage userPosition, GammaModifyInfo memory modifyInfo)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketWrapper.sol

12:     function executeTrade(GammaOrder memory gammaOrder, bytes memory sig, SettlementParamsV3 memory settlementParams)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketWrapper.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

7:     function decodeGammaModifyInfo(bytes32 args, uint256 lowerLimit, uint256 upperLimit, int64 maximaDeviation)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

118:     function validateLimitPrice(uint256 tradePrice, int256 tradeAmount, uint256 limitPrice)

178:     function ratio(uint256 price1, uint256 price2) internal pure returns (uint256) {

188:     function validateMarketOrder(uint256 tradePrice, int256 tradeAmount, bytes memory auctionData)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

92:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

149:     function executeOrderV3(SignedOrder memory order, SettlementParamsV3 memory settlementParams)

220:     function _calculateInitialMargin(uint256 vaultId, uint256 pairId, uint256 leverage)

236:     function _calculateNetValue(DataType.Vault memory vault, uint256 price) internal pure returns (uint256) {

242:     function _calculatePositionValue(DataType.Vault memory vault, uint256 sqrtPrice) internal pure returns (int256) {

247:     function getUserPosition(address owner, uint256 pairId)

265:     function _saveUserPosition(UserPosition storage userPosition, PerpOrder memory perpOrder) internal {

314:     function _verifyOrder(ResolvedOrder memory order, uint256 amount) internal {

327:     function _verifyOrderV3(ResolvedOrder memory order, uint256 amount) internal {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/markets/perp/PerpOrder.sol

54:     function hash(PerpOrder memory order) internal pure returns (bytes32) {

73:     function resolve(PerpOrder memory perpOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrder.sol)

```solidity
File: src/markets/perp/PerpOrderV3.sol

58:     function hash(PerpOrderV3 memory order) internal pure returns (bytes32) {

78:     function resolve(PerpOrderV3 memory perpOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpOrderV3.sol)

```solidity
File: src/settlements/UniswapSettlement.sol

58:     function quoteSwapExactIn(bytes memory data, uint256 amountIn) external override returns (uint256 amountOut) {

62:     function quoteSwapExactOut(bytes memory data, uint256 amountOut) external override returns (uint256 amountIn) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/settlements/UniswapSettlement.sol)

```solidity
File: src/tokenization/SupplyToken.sol

21:     function mint(address account, uint256 amount) external virtual override onlyController {

25:     function burn(address account, uint256 amount) external virtual override onlyController {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

```solidity
File: src/types/GlobalData.sol

26:     function validateVaultId(GlobalDataLibrary.GlobalData storage globalData, uint256 vaultId) internal view {

30:     function validate(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) internal view {

35:     function initializeLock(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) internal {

62:     function finalizeLock(GlobalDataLibrary.GlobalData storage globalData)

72:     function take(GlobalDataLibrary.GlobalData storage globalData, bool isQuoteAsset, address to, uint256 amount)

88:     function settle(GlobalDataLibrary.GlobalData storage globalData, bool isQuoteAsset)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

```solidity
File: src/vendors/AggregatorV3Interface.sol

5:     function decimals() external view returns (uint8);

6:     function description() external view returns (string memory);

7:     function version() external view returns (uint256);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/vendors/AggregatorV3Interface.sol)

```solidity
File: src/vendors/IPyth.sol

16:     function getPrice(bytes32 id) external view returns (Price memory price);

23:     function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (Price memory price);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/vendors/IPyth.sol)

```solidity
File: src/vendors/IUniswapV3PoolOracle.sol

18:     function liquidity() external view returns (uint128);

30:     function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/vendors/IUniswapV3PoolOracle.sol)

### <a name="NC-7"></a>[NC-7] Change uint to uint256
Throughout the code base, some variables are declared as `uint`. To favor explicitness, consider changing all instances of `uint` to `uint256`

*Instances (11)*:
```solidity
File: src/markets/L2Decoder.sol

23:             isLimitUint := and(shr(192, args1), 0xFFFFFFFF)

26:         if (isLimitUint == 1) {

63:             reduceOnlyUint := and(shr(136, args), 0xFF)

64:             closePositionUint := and(shr(144, args), 0xFF)

65:             sideUint := and(shr(152, args), 0xFF)

68:         reduceOnly = reduceOnlyUint == 1;

69:         closePosition = closePositionUint == 1;

70:         side = sideUint == 1;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/L2Decoder.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

65:         uint32 isEnabledUint = 0;

74:             isEnabledUint := and(shr(224, args), 0xFFFF)

78:         if (isEnabledUint == 1) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

### <a name="NC-8"></a>[NC-8] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor
If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (14)*:
```solidity
File: src/PredyPool.sol

48:         if (operator != msg.sender) revert CallerIsNotOperator();

54:         if (msg.sender != locker) revert LockedBy(locker);

59:         if (globalData.pairs[pairId].poolOwner != msg.sender) revert CallerIsNotPoolCreator();

64:         if (globalData.vaults[vaultId].owner != msg.sender) revert CallerIsNotVaultOwner();

80:         require(allowedUniswapPools[msg.sender]);

272:         if (globalData.pairs[tradeParams.pairId].allowlistEnabled && !allowedTraders[msg.sender][tradeParams.pairId]) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallback.sol

17:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallback.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

16:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

32:         if (msg.sender != whitelistFiller) revert CallerIsNotFiller();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/libraries/VaultLib.sol

19:         if (vault.owner != msg.sender) {

51:             if (vault.owner != msg.sender) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/VaultLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

180:             if (msg.sender != whitelistFiller) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

202:             if (msg.sender != whitelistFiller) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/tokenization/SupplyToken.sol

11:         require(_controller == msg.sender, "ST0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

### <a name="NC-9"></a>[NC-9] Consider using named mappings
Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/questions/51629/how-to-name-the-arguments-in-mapping/145555#145555) to make it easier to understand the purpose of each mapping

*Instances (13)*:
```solidity
File: src/PredyPool.sol

38:     mapping(address => bool) public allowedUniswapPools;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/libraries/ApplyInterestLib.sol

26:     function applyInterestForToken(mapping(uint256 => DataType.PairStatus) storage pairs, uint256 pairId) internal {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/libraries/PerpFee.sol

18:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,

43:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,

114:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,

139:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PerpFee.sol)

```solidity
File: src/libraries/Trade.sol

137:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

55:         mapping(address => bool) storage allowedUniswapPools,

144:         mapping(uint256 => DataType.PairStatus) storage _pairs,

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

132:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) storage rebalanceFeeGrowthCache

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/types/GlobalData.sol

20:         mapping(uint256 => DataType.PairStatus) pairs;

21:         mapping(uint256 => DataType.RebalanceFeeGrowthCache) rebalanceFeeGrowthCache;

22:         mapping(uint256 => DataType.Vault) vaults;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

### <a name="NC-10"></a>[NC-10] Take advantage of Custom Error's return value property
An important feature of Custom Error is that values such as address, tokenID, msg.value can be written inside the () sign, this kind of approach provides a serious advantage in debugging and examining the revert details of dapps such as tenderly.

*Instances (54)*:
```solidity
File: src/PredyPool.sol

48:         if (operator != msg.sender) revert CallerIsNotOperator();

59:         if (globalData.pairs[pairId].poolOwner != msg.sender) revert CallerIsNotPoolCreator();

64:         if (globalData.vaults[vaultId].owner != msg.sender) revert CallerIsNotVaultOwner();

273:             revert TraderNotAllowed();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallback.sol

17:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallback.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

16:         if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

32:         if (msg.sender != whitelistFiller) revert CallerIsNotFiller();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

36:             revert IFillerMarket.SettlementContractIsNotWhitelisted();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/Perp.sol

437:             revert OutOfRangeError();

555:                 revert SqrtAssetCanNotCoverBorrow();

567:                 revert SqrtAssetCanNotCoverBorrow();

724:             revert NoCFMMLiquidityError();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PositionCalculator.sol

59:             revert NotSafe();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/SlippageLib.sol

30:             revert InvalidAveragePrice();

36:                 revert SlippageTooLarge();

41:                 revert SlippageTooLarge();

52:             revert OutOfAcceptablePriceRange();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/Trade.sol

99:             revert IPredyPool.BaseTokenNotSettled();

104:             revert IPredyPool.QuoteTokenNotSettled();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/VaultLib.sol

20:             revert IPredyPool.CallerIsNotVaultOwner();

52:                 revert IPredyPool.CallerIsNotVaultOwner();

56:                 revert IPredyPool.VaultAlreadyHasAnotherMarginId();

60:                 revert IPredyPool.VaultAlreadyHasAnotherPair();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/VaultLib.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

73:             revert InvalidUniswapPool();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

61:                     revert IPredyPool.QuoteTokenNotSettled();

65:                     revert IPredyPool.BaseTokenNotSettled();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

30:             revert IPredyPool.InvalidAmount();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/libraries/logic/TradeLogic.sol

80:             revert IPredyPool.BaseTokenNotSettled();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/TradeLogic.sol)

```solidity
File: src/libraries/orders/DecayLib.sol

22:             revert EndTimeBeforeStartTime();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/DecayLib.sol)

```solidity
File: src/libraries/orders/ResolvedOrder.sol

25:             revert InvalidMarket();

29:             revert DeadlinePassed();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/ResolvedOrder.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

91:                     revert MarginUpdateMustBeZero();

181:                 revert CallerIsNotFiller();

213:             revert InvalidOrder();

234:             revert PositionNotFound();

244:             revert HedgeTriggerNotMatched();

257:             revert DeltaIsZero();

282:             revert PositionNotFound();

292:             revert AutoCloseTriggerNotMatched();

307:             revert AlreadyClosed();

396:             revert PositionIsNotClosed();

422:             revert PositionNotFound();

426:             revert SignerIsNotPositionOwner();

430:             revert PositionHasDifferentPairId();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

198:             revert TooShortHedgeInterval();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

95:                 revert MarketOrderDoesNotMatch();

103:                 revert LimitStopOrderDoesNotMatch();

108:                 revert LimitPriceDoesNotMatch();

113:                 revert StopPriceDoesNotMatch();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

182:             revert AmountIsZero();

203:                 revert CallerIsNotFiller();

291:             revert AmountIsZero();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/types/GlobalData.sol

27:         if (vaultId <= 0 || globalData.vaultCount <= vaultId) revert IPredyPool.InvalidPairId();

31:         if (pairId <= 0 || globalData.pairsCount <= pairId) revert IPredyPool.InvalidPairId();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

### <a name="NC-11"></a>[NC-11] Avoid the use of sensitive terms
Use [alternative variants](https://www.zdnet.com/article/mysql-drops-master-slave-and-blacklist-whitelist-terminology/), e.g. allowlist/denylist instead of whitelist/blacklist

*Instances (28)*:
```solidity
File: src/base/BaseMarket.sol

11:     address public whitelistFiller;

17:     mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

19:     constructor(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)

23:         whitelistFiller = _whitelistFiller;

36:         SettlementCallbackLib.validate(_whiteListedSettlements, settlementParams);

84:     function updateWhitelistFiller(address newWhitelistFiller) external onlyOwner {

85:         whitelistFiller = newWhitelistFiller;

92:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyOwner {

93:         _whiteListedSettlements[settlementContractAddress] = isEnabled;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

23:     address public whitelistFiller;

29:     mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

32:         if (msg.sender != whitelistFiller) revert CallerIsNotFiller();

38:     function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)

44:         whitelistFiller = _whitelistFiller;

57:         SettlementCallbackLib.validate(_whiteListedSettlements, settlementParams);

128:     function updateWhitelistFiller(address newWhitelistFiller) external onlyFiller {

129:         whitelistFiller = newWhitelistFiller;

140:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyFiller {

141:         _whiteListedSettlements[settlementContractAddress] = isEnabled;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

30:         mapping(address settlementContractAddress => bool) storage _whiteListedSettlements,

34:             settlementParams.contractAddress != address(0) && !_whiteListedSettlements[settlementParams.contractAddress]

36:             revert IFillerMarket.SettlementContractIsNotWhitelisted();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

69:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

74:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

180:             if (msg.sender != whitelistFiller) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

92:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

97:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

202:             if (msg.sender != whitelistFiller) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

### <a name="NC-12"></a>[NC-12] Some require descriptions are not clear
1. It does not comply with the general require error description model of the project (Either all of them should be debugged in this way, or all of them should be explained with a string not exceeding 32 bytes.)
2. For debug dapps like Tenderly, these debug messages are important, this allows the user to see the reasons for revert practically.

*Instances (18)*:
```solidity
File: src/PredyPool.sol

182:         require(amount > 0, "AZ");

204:         require(amount > 0, "AZ");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/libraries/ScaledAsset.sol

55:         require(_supplyTokenAmount > 0, "S3");

67:         require(getAvailableCollateralValue(tokenState) >= finalWithdrawAmount, "S0");

85:             require(userStatus.lastFeeGrowth == tokenStatus.assetGrowth, "S2");

87:             require(userStatus.lastFeeGrowth == tokenStatus.debtGrowth, "S2");

108:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-closeAmount), "S0");

118:             require(getAvailableCollateralValue(tokenStatus) >= uint256(-openAmount), "S0");

160:         require(accountState.positionAmount >= 0, "S1");

175:         require(accountState.positionAmount <= 0, "S1");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ScaledAsset.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

76:         require(uniswapPool.token0() == stableTokenAddress || uniswapPool.token1() == stableTokenAddress, "C3");

153:         require(_pairs[_pairId].id == 0, "AAA");

206:         require(_fee <= 20, "FEE");

214:         require(1e8 < _assetRiskParams.riskRatio && _assetRiskParams.riskRatio <= 10 * 1e8, "C0");

216:         require(_assetRiskParams.rangeSize > 0 && _assetRiskParams.rebalanceThreshold > 0, "C0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

45:         require(closeRatio > 0 && closeRatio <= 1e18, "ICR");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/logic/SupplyLogic.sol

64:         require(_amount > 0, "AZ");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/SupplyLogic.sol)

```solidity
File: src/tokenization/SupplyToken.sol

11:         require(_controller == msg.sender, "ST0");

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/tokenization/SupplyToken.sol)

### <a name="NC-13"></a>[NC-13] Use Underscores for Number Literals (add an underscore every 3 digits)

*Instances (14)*:
```solidity
File: src/libraries/Constants.sol

7:     uint256 internal constant MAX_VAULTS = 18446744073709551616;

8:     uint256 internal constant MAX_PAIRS = 18446744073709551616;

15:     uint256 internal constant MIN_SQRT_PRICE = 79228162514264337593;

16:     uint256 internal constant MAX_SQRT_PRICE = 79228162514264337593543950336000000000;

23:     uint256 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 1000;

25:     uint256 internal constant BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE = 12422;

27:     uint256 internal constant MAX_LIQ_SLIPPAGE_SQRT_TOLERANCE = 24710;

29:     uint256 internal constant SLIPPAGE_SQRT_TOLERANCE = 12422;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Constants.sol)

```solidity
File: src/libraries/Perp.sol

399:             f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

402:             f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

405:         _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);

406:         _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/SlippageLib.sol

13:     uint256 public constant MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 100747209;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

27:     uint256 constant _MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 101488915;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

### <a name="NC-14"></a>[NC-14] Constants should be defined rather than using magic numbers

*Instances (16)*:
```solidity
File: src/libraries/PremiumCurveModel.sol

21:         return (1600 * b * b / Constants.ONE) / Constants.ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PremiumCurveModel.sol)

```solidity
File: src/markets/L2Decoder.sol

21:             startTime := and(shr(64, args1), 0xFFFFFFFFFFFFFFFF)

23:             isLimitUint := and(shr(192, args1), 0xFFFFFFFF)

45:             pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)

61:             pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)

63:             reduceOnlyUint := and(shr(136, args), 0xFF)

64:             closePositionUint := and(shr(144, args), 0xFF)

65:             sideUint := and(shr(152, args), 0xFF)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/L2Decoder.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

45:             pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)

47:             leverage := and(shr(160, args), 0xFF)

69:             hedgeInterval := and(shr(64, args), 0xFFFFFFFF)

70:             sqrtPriceTrigger := and(shr(96, args), 0xFFFFFFFF)

72:             maxSlippageTolerance := and(shr(160, args), 0xFFFFFFFF)

73:             auctionRange := and(shr(192, args), 0xFFFFFFFF)

74:             isEnabledUint := and(shr(224, args), 0xFFFF)

75:             auctionPeriod := and(shr(240, args), 0xFFFF)

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

### <a name="NC-15"></a>[NC-15] Variables need not be initialized to zero
The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (5)*:
```solidity
File: src/libraries/logic/LiquidationLogic.sol

87:         uint256 sentMarginAmount = 0;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/markets/gamma/ArrayLib.sol

23:         for (uint256 i = 0; i < items.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/ArrayLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

366:         for (uint64 i = 0; i < userPositionIDs.length; i++) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/gamma/L2GammaDecoder.sol

65:         uint32 isEnabledUint = 0;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/L2GammaDecoder.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

117:             uint256 cost = 0;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | `approve()`/`safeApprove()` may revert if the current approval is not zero | 4 |
| [L-2](#L-2) | `decimals()` is not a part of the ERC-20 standard | 1 |
| [L-3](#L-3) | `decimals()` should be of type `uint8` | 2 |
| [L-4](#L-4) | Division by zero not prevented | 43 |
| [L-5](#L-5) | External call recipient may consume all transaction gas | 9 |
| [L-6](#L-6) | Initializers could be front-run | 13 |
| [L-7](#L-7) | Signature use at deadlines should be allowed | 3 |
| [L-8](#L-8) | Possible rounding issue | 5 |
| [L-9](#L-9) | Loss of precision | 16 |
| [L-10](#L-10) | `symbol()` is not a part of the ERC-20 standard | 1 |
| [L-11](#L-11) | Unsafe ERC20 operation(s) | 4 |
| [L-12](#L-12) | Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions | 8 |
| [L-13](#L-13) | Upgradeable contract not initialized | 30 |
### <a name="L-1"></a>[L-1] `approve()`/`safeApprove()` may revert if the current approval is not zero
- Some tokens (like the *very popular* USDT) do not work when changing the allowance from an existing non-zero allowance value (it will revert if the current approval is not zero to protect against front-running changes of approvals). These tokens must first be approved for zero and then the actual allowance can be approved.
- Furthermore, OZ's implementation of safeApprove would throw an error if an approve is attempted from a non-zero value (`"SafeERC20: approve from non-zero to non-zero allowance"`)

Set the allowance to zero immediately before each of the existing allowance calls

*Instances (4)*:
```solidity
File: src/base/SettlementCallbackLib.sol

111:         ERC20(baseToken).approve(address(settlementParams.contractAddress), sellAmount);

158:         ERC20(quoteToken).approve(address(settlementParams.contractAddress), settlementParams.maxQuoteAmount);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/settlements/UniswapSettlement.sol

31:         ERC20(baseToken).approve(address(_swapRouter), amountIn);

47:         ERC20(quoteToken).approve(address(_swapRouter), amountInMaximum);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/settlements/UniswapSettlement.sol)

### <a name="L-2"></a>[L-2] `decimals()` is not a part of the ERC-20 standard
The `decimals()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (1)*:
```solidity
File: src/libraries/logic/AddPairLogic.sol

200:                 erc20.decimals()

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

### <a name="L-3"></a>[L-3] `decimals()` should be of type `uint8`

*Instances (2)*:
```solidity
File: src/PriceFeed.sol

18:     function createPriceFeed(address quotePrice, bytes32 priceId, uint256 decimalsDiff) external returns (address) {

37:     constructor(address quotePrice, address pyth, bytes32 priceId, uint256 decimalsDiff) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

### <a name="L-4"></a>[L-4] Division by zero not prevented
The divisions below take an input parameter which does not have any zero-value checks, which may lead to the functions reverting when zero is passed.

*Instances (43)*:
```solidity
File: src/PriceFeed.sol

54:         uint256 price = uint256(int256(basePrice.price)) * Constants.Q96 / uint256(quoteAnswer);

55:         price = price * Constants.Q96 / _decimalsDiff;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PriceFeed.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

70:         uint256 fee = settlementParamsV3.feePrice * tradeAmountAbs / Constants.Q96;

76:         uint256 maxQuoteAmount = settlementParamsV3.maxQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

77:         uint256 minQuoteAmount = settlementParamsV3.minQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/base/SettlementCallbackLib.sol

101:             uint256 quoteAmount = sellAmount * price / Constants.Q96;

125:             uint256 quoteAmount = sellAmount * price / Constants.Q96;

148:             uint256 quoteAmount = buyAmount * price / Constants.Q96;

172:             uint256 quoteAmount = buyAmount * price / Constants.Q96;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/libraries/InterestRateModel.sol

26:             ir += (utilizationRatio * irmParams.slope1) / _ONE;

28:             ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;

29:             ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/InterestRateModel.sol)

```solidity
File: src/libraries/Perp.sol

168:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

172:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

609:         uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

689:                 int256 closeStableAmount = _entryValue * _tradeAmount / _positionAmount;

697:                 int256 openStableAmount = _valueUpdate * (_positionAmount + _tradeAmount) / _tradeAmount;

785:             offsetStable += closeAmount * _userStatus.sqrtPerp.quoteRebalanceEntryValue / _userStatus.sqrtPerp.amount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PositionCalculator.sol

194:         uint256 lowerPrice = _sqrtPrice * RISK_RATIO_ONE / _riskRatio;

213:                 (uint256(-_positionParams.amountSqrt) * Constants.Q96) / uint256(_positionParams.amountBase);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/PremiumCurveModel.sol

21:         return (1600 * b * b / Constants.ONE) / Constants.ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PremiumCurveModel.sol)

```solidity
File: src/libraries/Reallocation.sol

120:         result = (result / tickSpacing) * tickSpacing;

170:         uint160 sqrtPrice = (available * FixedPoint96.Q96 / liquidityAmount).toUint160();

184:         uint256 denominator1 = available * sqrtRatioB / FixedPoint96.Q96;

190:         uint160 sqrtPrice = uint160(liquidityAmount * sqrtRatioB / (liquidityAmount - denominator1));

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Reallocation.sol)

```solidity
File: src/libraries/SlippageLib.sol

48:                     tradeResult.sqrtPrice < sqrtBasePrice * 1e8 / maxAcceptableSqrtPriceRange

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/Trade.sol

128:         swapResult.amountPerp = amountQuote * swapParams.amountPerp / amountBase;

132:         swapResult.averagePrice = amountQuote * int256(Constants.Q96) / Math.abs(amountBase).toInt256();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/UniHelper.sol

29:             return uint160((Constants.Q96 << Constants.RESOLUTION) / sqrtPriceX96);

70:         int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int256(ago)));

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/logic/LiquidationLogic.sol

168:         uint256 ratio = uint256(vaultValue * 1e4 / minMargin);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/LiquidationLogic.sol)

```solidity
File: src/libraries/math/Bps.sol

12:         return price * ONE / bps;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Bps.sol)

```solidity
File: src/libraries/orders/DecayLib.sol

32:                 decayedPrice = startPrice - (startPrice - endPrice) * elapsed / duration;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/orders/DecayLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

56:         return perpAmount + _sqrtAmount * int256(Constants.Q96) / sqrtPrice;

84:         uint256 upperThreshold = userPosition.lastHedgedSqrtPrice * userPosition.sqrtPriceTrigger / Bps.ONE;

85:         uint256 lowerThreshold = userPosition.lastHedgedSqrtPrice * Bps.ONE / userPosition.sqrtPriceTrigger;

150:         uint256 elapsed = (currentTime - startTime) * Bps.ONE / auctionParams.auctionPeriod;

176:         uint256 ratio = (price2 * Bps.ONE / price1 - Bps.ONE);

185:                     / auctionParams.auctionRange

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketLib.sol

182:             return (price1 - price2) * Bps.ONE / price2;

184:             return (price2 - price1) * Bps.ONE / price2;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketLib.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

233:         return (netValue / leverage).toInt256() - _calculatePositionValue(vault, sqrtPrice);

239:         return Math.abs(positionAmount) * price / Constants.Q96;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

### <a name="L-5"></a>[L-5] External call recipient may consume all transaction gas
There is no limit specified on the amount of gas used, so the recipient can use up all of the transaction's gas, causing it to revert. Use `addr.call{gas: <amount>}("")` or [this](https://github.com/nomad-xyz/ExcessivelySafeCall) library instead.

*Instances (9)*:
```solidity
File: src/libraries/Trade.sol

94:         globalData.callSettlementCallback(settlementData, totalBaseAmount);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

54:                 globalData.callSettlementCallback(settlementData, deltaPositionBase);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

86:         if (callbackData.callbackType == GammaTradeMarketLib.CallbackType.QUOTE) {

110:                     callbackData.callbackType == GammaTradeMarketLib.CallbackType.TRADE

112:                         : callbackData.callbackType

132:                     callbackData.callbackType

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

109:         if (callbackData.callbackSource == CallbackSource.QUOTE) {

111:         } else if (callbackData.callbackSource == CallbackSource.QUOTE3) {

113:         } else if (callbackData.callbackSource == CallbackSource.TRADE3) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

### <a name="L-6"></a>[L-6] Initializers could be front-run
Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

*Instances (13)*:
```solidity
File: src/PredyPool.sol

70:     function initialize(address uniswapFactory) public initializer {

71:         __ReentrancyGuard_init();

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

20:     function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

38:     function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)

42:         __BaseHookCallback_init(predyPool);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

69:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

71:         initializer

73:         __ReentrancyGuard_init();

74:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

92:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

94:         initializer

96:         __ReentrancyGuard_init();

97:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

### <a name="L-7"></a>[L-7] Signature use at deadlines should be allowed
According to [EIP-2612](https://github.com/ethereum/EIPs/blob/71dc97318013bf2ac572ab63fab530ac9ef419ca/EIPS/eip-2612.md?plain=1#L58), signatures used on exactly the deadline timestamp are supposed to be allowed. While the signature may or may not be used for the exact EIP-2612 use case (transfer approvals), for consistency's sake, all deadlines should follow this semantic. If the timestamp is an expiration rather than a deadline, consider whether it makes more sense to include the expiration timestamp as a valid timestamp, as is done for deadlines.

*Instances (3)*:
```solidity
File: src/libraries/ApplyInterestLib.sol

32:         if (pairStatus.lastUpdateTimestamp >= block.timestamp) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/ApplyInterestLib.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

66:                 && userPosition.lastHedgedTime + userPosition.hedgeInterval <= block.timestamp

111:         if (userPosition.expiration <= block.timestamp) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

### <a name="L-8"></a>[L-8] Possible rounding issue
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator. Also, there is indication of multiplication and division without the use of parenthesis which could result in issues.

*Instances (5)*:
```solidity
File: src/libraries/Perp.sol

168:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

172:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

399:             f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

402:             f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

609:         uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

### <a name="L-9"></a>[L-9] Loss of precision
Division by large numbers may result in the result being zero, due to solidity not supporting fractions. Consider requiring a minimum amount for the numerator to ensure that it is always larger than the denominator

*Instances (16)*:
```solidity
File: src/libraries/InterestRateModel.sol

26:             ir += (utilizationRatio * irmParams.slope1) / _ONE;

28:             ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;

29:             ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/InterestRateModel.sol)

```solidity
File: src/libraries/Perp.sol

168:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

172:             ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

399:             f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

402:             f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount

590:         uint256 buffer = Math.max(_assetStatus.totalAmount / 50, Constants.MIN_LIQUIDITY);

609:         uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Perp.sol)

```solidity
File: src/libraries/PositionCalculator.sol

193:         uint256 upperPrice = _sqrtPrice * _riskRatio / RISK_RATIO_ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PositionCalculator.sol)

```solidity
File: src/libraries/PremiumCurveModel.sol

21:         return (1600 * b * b / Constants.ONE) / Constants.ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/PremiumCurveModel.sol)

```solidity
File: src/libraries/SlippageLib.sol

48:                     tradeResult.sqrtPrice < sqrtBasePrice * 1e8 / maxAcceptableSqrtPriceRange

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/SlippageLib.sol)

```solidity
File: src/libraries/math/Bps.sol

8:         return price * bps / ONE;

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/math/Bps.sol)

```solidity
File: src/markets/gamma/GammaTradeMarketLib.sol

84:         uint256 upperThreshold = userPosition.lastHedgedSqrtPrice * userPosition.sqrtPriceTrigger / Bps.ONE;

158:                 + elapsed * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance) / Bps.ONE

176:         uint256 ratio = (price2 * Bps.ONE / price1 - Bps.ONE);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarketLib.sol)

### <a name="L-10"></a>[L-10] `symbol()` is not a part of the ERC-20 standard
The `symbol()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (1)*:
```solidity
File: src/libraries/logic/AddPairLogic.sol

199:                 string.concat("p", erc20.symbol()),

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

### <a name="L-11"></a>[L-11] Unsafe ERC20 operation(s)

*Instances (4)*:
```solidity
File: src/base/SettlementCallbackLib.sol

111:         ERC20(baseToken).approve(address(settlementParams.contractAddress), sellAmount);

158:         ERC20(quoteToken).approve(address(settlementParams.contractAddress), settlementParams.maxQuoteAmount);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/SettlementCallbackLib.sol)

```solidity
File: src/settlements/UniswapSettlement.sol

31:         ERC20(baseToken).approve(address(_swapRouter), amountIn);

47:         ERC20(quoteToken).approve(address(_swapRouter), amountInMaximum);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/settlements/UniswapSettlement.sol)

### <a name="L-12"></a>[L-12] Upgradeable contract is missing a `__gap[50]` storage variable to allow for new storage variables in later versions
See [this](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps) link for a description of this storage variable. While some contracts may not currently be sub-classed, adding the variable now protects against forgetting to add it in the future.

*Instances (8)*:
```solidity
File: src/PredyPool.sol

6: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

28: contract PredyPool is IPredyPool, IUniswapV3MintCallback, Initializable, ReentrancyGuardUpgradeable {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

4: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

6: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

24: contract GammaTradeMarket is IFillerMarket, BaseMarketUpgradable, ReentrancyGuardUpgradeable {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

29: contract PerpMarketV1 is BaseMarketUpgradable, ReentrancyGuardUpgradeable {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

### <a name="L-13"></a>[L-13] Upgradeable contract not initialized
Upgradeable contracts are initialized via an initializer function rather than by a constructor. Leaving such a contract uninitialized may lead to it being taken over by a malicious user

*Instances (30)*:
```solidity
File: src/PredyPool.sol

6: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

28: contract PredyPool is IPredyPool, IUniswapV3MintCallback, Initializable, ReentrancyGuardUpgradeable {

70:     function initialize(address uniswapFactory) public initializer {

71:         __ReentrancyGuard_init();

72:         AddPairLogic.initializeGlobalData(globalData, uniswapFactory);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/PredyPool.sol)

```solidity
File: src/base/BaseHookCallbackUpgradable.sol

4: import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

20:     function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseHookCallbackUpgradable.sol)

```solidity
File: src/base/BaseMarketUpgradable.sol

38:     function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)

42:         __BaseHookCallback_init(predyPool);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarketUpgradable.sol)

```solidity
File: src/libraries/Trade.sol

92:         globalData.initializeLock(pairId);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/Trade.sol)

```solidity
File: src/libraries/UniHelper.sol

51:             (uint32 oldestAvailableAge,,, bool initialized) = uniswapPool.observations((index + 1) % cardinality);

53:             if (!initialized) {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/UniHelper.sol)

```solidity
File: src/libraries/logic/AddPairLogic.sol

44:     function initializeGlobalData(GlobalDataLibrary.GlobalData storage global, address uniswapFactory) external {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/AddPairLogic.sol)

```solidity
File: src/libraries/logic/ReallocationLogic.sol

52:                 globalData.initializeLock(pairId);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/ReallocationLogic.sol)

```solidity
File: src/libraries/logic/TradeLogic.sol

73:         globalData.initializeLock(tradeParams.pairId);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/libraries/logic/TradeLogic.sol)

```solidity
File: src/markets/gamma/GammaTradeMarket.sol

6: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

24: contract GammaTradeMarket is IFillerMarket, BaseMarketUpgradable, ReentrancyGuardUpgradeable {

69:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

71:         initializer

73:         __ReentrancyGuard_init();

74:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/gamma/GammaTradeMarket.sol)

```solidity
File: src/markets/perp/PerpMarketV1.sol

8: import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

29: contract PerpMarketV1 is BaseMarketUpgradable, ReentrancyGuardUpgradeable {

92:     function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)

94:         initializer

96:         __ReentrancyGuard_init();

97:         __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/markets/perp/PerpMarketV1.sol)

```solidity
File: src/types/GlobalData.sol

35:     function initializeLock(GlobalDataLibrary.GlobalData storage globalData, uint256 pairId) internal {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/types/GlobalData.sol)

```solidity
File: src/vendors/IUniswapV3PoolOracle.sol

28:         returns (uint32 blockTimestamp, int56 tickCumulative, uint160 liquidityCumulative, bool initialized);

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/vendors/IUniswapV3PoolOracle.sol)


## Medium Issues


| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Centralization Risk for trusted owners | 4 |
### <a name="M-1"></a>[M-1] Centralization Risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (4)*:
```solidity
File: src/base/BaseMarket.sol

10: abstract contract BaseMarket is IFillerMarket, BaseHookCallback, Owned {

21:         Owned(msg.sender)

84:     function updateWhitelistFiller(address newWhitelistFiller) external onlyOwner {

92:     function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyOwner {

```
[Link to code](https://github.com/code-423n4/2024-05-predy/blob/main/src/base/BaseMarket.sol)
