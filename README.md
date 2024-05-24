# Predy audit details
- Total Prize Pool: $100,000 in USDC
  - HM awards: $79,700 in USDC
  - QA awards: $3,300 in USDC
  - Judge awards: $9,900 in USDC
  - Lookout awards: 6,600 in USDC
  - Scout awards: $500 in USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2024-05-predy/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts May 24, 2024 20:00 UTC
- Ends June 14, 2024 20:00 UTC

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-05-predy/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

- Very large quantities of tokens are not supported. It should be assumed that for any given pool, the cumulative amount of tokens that enter the system will not exceed 2^127 - 1.
- Price or oracle manipulation that is not atomic or requires attackers to hold a price across more than one block (e.g., to manipulate a Uniswap observation, you need to set the manipulated price at the end of one block and then keep it there until the next block) is out of scope.
- Attacks that stem from the TWAP being extremely stale compared to the market price within its period (currently 30 minutes) are a known risk. As a general rule, only price manipulation issues that can be triggered by manipulating the price atomically from a normal pool or oracle state are valid.
- Premium manipulation: If the liquidity of a Uniswap pool is small enough, premium manipulation through large swaps in Uniswap is a known risk. This is acceptable as long as it does not cause a loss to the protocol.
- Front-running via insufficient slippage specification is out of scope.


# Overview

Predy is an on-chain exchange for trading Gamma and Perpetuals. It features Squart, which allows trading of perpetuals with gamma exposure covered by Uniswap V3.

## Architecture

This project features multiple market contracts centered around PredyPool. The market contracts define financial products and order types. Markets can leverage positions by utilizing PredyPool for token lending and borrowing. This architecture is highly scalable. For example, developers can create new futures exchanges with minimal code and gain leverage by connecting to PredyPool.

### PredyPool.sol

Short ETH(Base token) flow.

![diagram](https://github.com/code-423n4/2024-05-predy/blob/main/assets/PredyPool.mermaid.png?raw=true)

### PerpMarket.sol

Limit order flow of PerpMarket.

![diagram](https://github.com/code-423n4/2024-05-predy/blob/main/assets/PerpMarket.mermaid.png?raw=true)


### SpotMarket.sol

Market order flow of SpotMarket.

![diagram](https://github.com/code-423n4/2024-05-predy/blob/main/assets/SpotMarket.mermaid.png?raw=true)



## Links

- **Previous audits:**  N/A
- **Documentation:** https://docs.predy.finance/predy-v6
- **Website:** https://www.predy.finance/
- **X/Twitter:** https://x.com/predyfinance
- **Discord:** https://discord.com/invite/predy

---


# Scope

*See [scope.txt](https://github.com/code-423n4/2024-05-predy/blob/main/scope.txt)*

### Files in scope



| File   | Logic Contracts | Interfaces | SLOC  | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/PredyPool.sol | 1| **** | 209 | Holds the state for all pairs and vaults |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol<br>@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol<br>@solmate/src/utils/SafeTransferLib.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/PriceFeed.sol | 2| **** | 39 | A contract that provides the square root of the oracle price. |@solmate/src/utils/FixedPointMathLib.sol|
| /src/base/BaseHookCallback.sol | 1| **** | 18 | ||
| /src/base/BaseHookCallbackUpgradable.sol | 1| **** | 20 | |@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol|
| /src/base/BaseMarket.sol | 1| **** | 90 | The base contract for the market contract |@solmate/src/auth/Owned.sol|
| /src/base/BaseMarketUpgradable.sol | 1| **** | 127 | The base contract for an upgradable market contract ||
| /src/base/SettlementCallbackLib.sol | 1| **** | 153 | A library that supports methods for token swap |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/ApplyInterestLib.sol | 1| **** | 65 | A library that updates interest rates and premiums ||
| /src/libraries/Constants.sol | 1| **** | 18 | A library that has constant values ||
| /src/libraries/DataType.sol | 1| **** | 34 | A library that defines data types ||
| /src/libraries/InterestRateModel.sol | 1| **** | 24 | A library that defines the interest rate curve ||
| /src/libraries/PairLib.sol | 1| **** | 6 | A library that validates pairs. ||
| /src/libraries/Perp.sol | 1| **** | 601 | A library for updating Perp and Squart positions |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-periphery/contracts/libraries/PositionKey.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@solmate/src/utils/SafeCastLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PerpFee.sol | 1| **** | 121 | A library that calculates and applies interest rates and premiums for Perp and Squart positions |@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PositionCalculator.sol | 1| **** | 177 | A library that calculates position value and Min. margin |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PremiumCurveModel.sol | 1| **** | 11 | A library that defines the premium curve ||
| /src/libraries/Reallocation.sol | 1| **** | 143 | A library that calculates the new range for reallocating LP ranges |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/ScaledAsset.sol | 1| **** | 190 | A library that defines tokens that accrue interest compounding through lending |@solmate/src/utils/FixedPointMathLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/SlippageLib.sol | 1| **** | 41 | A library that performs slippage checks ||
| /src/libraries/Trade.sol | 1| **** | 108 | A library for trading Perp and Squart |@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/UniHelper.sol | 1| **** | 107 | A library for obtaining TWAP and trading fees from UniswapV3Pool. |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-periphery/contracts/libraries/PositionKey.sol|
| /src/libraries/VaultLib.sol | 1| **** | 47 | A library for creating Vaults ||
| /src/libraries/logic/AddPairLogic.sol | 1| **** | 175 | Logic for adding and validating new pairs |@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol<br>@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol|
| /src/libraries/logic/LiquidationLogic.sol | 1| **** | 119 | Logic for forced liquidation |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/ReaderLogic.sol | 1| **** | 53 | A library for reading the state of pairs and vaults ||
| /src/libraries/logic/ReallocationLogic.sol | 1| **** | 70 | Logic for reallocating LP ranges. |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/SupplyLogic.sol | 1| **** | 67 | Logic for supplying and withdrawing tokens |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/TradeLogic.sol | 1| **** | 63 | Logic for trading Perp and Squart. ||
| /src/libraries/math/Bps.sol | 1| **** | 10 | A library for calculating n% above or below a given price. ||
| /src/libraries/math/LPMath.sol | 1| **** | 118 | A library for liquidity calculations related to Uniswap V3 LP positions. |@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/math/Math.sol | 1| **** | 54 | math library |@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@solmate/src/utils/FixedPointMathLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/orders/DecayLib.sol | 1| **** | 32 | math library ||
| /src/libraries/orders/OrderInfoLib.sol | 1| **** | 14 | Common order information library ||
| /src/libraries/orders/Permit2Lib.sol | 1| **** | 23 | A library that outputs parameters compatible with permit2 |@uniswap/permit2/src/interfaces/ISignatureTransfer.sol|
| /src/libraries/orders/ResolvedOrder.sol | 1| **** | 21 | A structure that extracts necessary information for validation from custom orders. ||
| /src/markets/L2Decoder.sol | 1| **** | 63 | A library for compressing calldata size. ||
| /src/markets/gamma/ArrayLib.sol | 1| **** | 24 | A library for pushing and removing item from array ||
| /src/markets/gamma/GammaOrder.sol | 2| **** | 118 | Orders for gamma trade market ||
| /src/markets/gamma/GammaTradeMarket.sol | 1| **** | 347 | The core of gamma trade market |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol<br>@uniswap/permit2/src/interfaces/IPermit2.sol|
| /src/markets/gamma/GammaTradeMarketL2.sol | 1| **** | 81 | A contract extends GammaTradeMarket to add L2 specific methods ||
| /src/markets/gamma/GammaTradeMarketLib.sol | 1| **** | 179 | A library for validating AutoHedge and AutoClose. ||
| /src/markets/gamma/GammaTradeMarketWrapper.sol | 1| **** | 13 | This is for testing purpose ||
| /src/markets/gamma/L2GammaDecoder.sol | 1| **** | 76 | A library for compressing calldata size. ||
| /src/markets/perp/PerpMarket.sol | 1| **** | 44 | A contract extends PerpMarketV1 to add L2 specific methods ||
| /src/markets/perp/PerpMarketLib.sol | 1| **** | 171 | A library for validating perp trades ||
| /src/markets/perp/PerpMarketV1.sol | 1| **** | 272 | The core of perp market |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@uniswap/permit2/src/interfaces/IPermit2.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol|
| /src/markets/perp/PerpOrder.sol | 1| **** | 63 | deprecate ||
| /src/markets/perp/PerpOrderV3.sol | 1| **** | 67 | A library for defining perp orders ||
| /src/settlements/UniswapSettlement.sol | 1| **** | 52 | A library for token swaps using Uniswap's Swap Router |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol<br>@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol|
| /src/tokenization/SupplyToken.sol | 1| **** | 21 | The bond token for the lending pool |@solmate/src/tokens/ERC20.sol|
| /src/types/GlobalData.sol | 1| **** | 90 | Provides global data and methods for locking when calling back from trade functions |@solmate/src/utils/SafeTransferLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/types/LockData.sol | 1| **** | 10 | Defines the data structure for locks ||
| /src/vendors/AggregatorV3Interface.sol | ****| 1 | 14 | An interface of Chainlink aggregator ||
| /src/vendors/IPyth.sol | ****| 1 | 11 | An interface of Pyth ||
| /src/vendors/IUniswapV3PoolOracle.sol | ****| 1 | 25 | An interface of UniswapV3PoolOracle ||
| **Totals** | **54** | **3** | **4909** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2024-05-predy/blob/main/out_of_scope.txt)*


## Scoping Q &amp; A

### General questions


| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              |       WETH, USDC, ARB, USDT, DAI, WBTC  |
| Test coverage                           | 67.73% (1270/1875 statements)            |
| ERC721 used  by the protocol            |            None              |
| ERC777 used by the protocol             |           None                |
| ERC1155 used by the protocol            |              None            |
| Chains the protocol will be deployed on | Arbitrum,Base,Optimism |

### External integrations (e.g., Uniswap) behavior in scope:


| Question                                                  | Answer |
| --------------------------------------------------------- | ------ |
| Enabling/disabling fees (e.g. Blur disables/enables fees) | No   |
| Pausability (e.g. Uniswap pool gets paused)               |  No   |
| Upgradeability (e.g. Uniswap gets upgraded)               |   No  |


### EIP compliance checklist

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| src/tokenization/SupplyToken.sol        | EIP20                        |


# Additional context

## Main invariants

- Assuming sufficient liquidity, safe vaults cannot be liquidated, whereas unsafe vaults can be liquidated. This ensures that only positions that pose a risk to the system are targeted for liquidation, maintaining the integrity of the platform.
- If there is sufficient liquidity and the range threshold conditions are met, the reallocation of the Uniswap V3 LP range is always possible.


## Attack ideas (where to focus for bugs)
We are concerned about callback exploits, similar to the attack described in [this blog](
https://predyfinance.medium.com/postmortem-report-on-the-details-of-the-events-of-may-14-2024-8690508c820b)

## All trusted roles in the protocol


| Role            | Description                  |
| --------------- | ---------------------------- |
| Operator        |  Operator can add a new pair |
| Pool Owner      |  Pool owner can update parameters related to the pair |

## Describe any novel or unique curve logic or mathematical models implemented in the contracts:

Calculating the Min. margin is unique. Please refer to [the documentation](https://docs.predy.finance/predy-v6/dev/position-value#min.-margin) for the calculation formula. 


## Running tests




```bash
git clone https://github.com/code-423n4/2024-05-predy
cd 2024-05-predy
foundryup --version nightly-5b7e4cb3c882b28f3c32ba580de27ce7381f415a  # this is to avoid some bug that occurs with the recent version of foundry
npm i
forge test
```

To run code coverage
```bash
forge coverage --ir-minimum
```

See [coverage table](https://github.com/code-423n4/2024-05-predy/blob/main/coverage-table.md) for coverage for files in scope



## Miscellaneous
Employees of Predy and employees' family members are ineligible to participate in this audit.



