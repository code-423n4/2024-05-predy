# ✨ So you want to run an audit

This `README.md` contains a set of checklists for our audit collaboration.

Your audit will use two repos: 
- **an _audit_ repo** (this one), which is used for scoping your audit and for providing information to wardens
- **a _findings_ repo**, where issues are submitted (shared with you after the audit) 

Ultimately, when we launch the audit, this repo will be made public and will contain the smart contracts to be reviewed and all the information needed for audit participants. The findings repo will be made public after the audit report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the audit sponsor (⭐️)**.

---

# Audit setup

## 🐺 C4: Set up repos
- [ ] Create a new private repo named `YYYY-MM-sponsorname` using this repo as a template.
- [ ] Rename this repo to reflect audit date (if applicable)
- [ ] Rename audit H1 below
- [ ] Update pot sizes
  - [ ] Remove the "Bot race findings opt out" section if there's no bot race.
- [ ] Fill in start and end times in audit bullets below
- [ ] Add link to submission form in audit details below
- [ ] Add the information from the scoping form to the "Scoping Details" section at the bottom of this readme.
- [ ] Add matching info to the Code4rena site
- [ ] Add sponsor to this private repo with 'maintain' level access.
- [ ] Send the sponsor contact the url for this repo to follow the instructions below and add contracts here. 
- [ ] Delete this checklist.

# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Confirm that this repo is a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 48 business hours prior to audit start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the audit — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the audit. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)

## ⭐️ Sponsor: Repo checklist

- [ ] Modify the [Overview](#overview) section of this `README.md` file. Describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the auditors should keep in mind when reviewing. (Here are two well-constructed examples: [Ajna Protocol](https://github.com/code-423n4/2023-05-ajna) and [Maia DAO Ecosystem](https://github.com/code-423n4/2023-05-maia))
- [ ] Review the Gas award pool amount, if applicable. This can be adjusted up or down, based on your preference - just flag it for Code4rena staff so we can update the pool totals across all comms channels.
- [ ] Optional: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] [This checklist in Notion](https://code4rena.notion.site/Key-info-for-Code4rena-sponsors-f60764c4c4574bbf8e7a6dbd72cc49b4#0cafa01e6201462e9f78677a39e09746) provides some best practices for Code4rena audit repos.

## ⭐️ Sponsor: Final touches
- [ ] Review and confirm the pull request created by the Scout (technical reviewer) who was assigned to your contest. *Note: any files not listed as "in scope" will be considered out of scope for the purposes of judging, even if the file will be part of the deployed contracts.*
- [ ] Check that images and other files used in this README have been uploaded to the repo as a file and then linked in the README using absolute path (e.g. `https://github.com/code-423n4/yourrepo-url/filepath.png`)
- [ ] Ensure that *all* links and image/file paths in this README use absolute paths, not relative paths
- [ ] Check that all README information is in markdown format (HTML does not render on Code4rena.com)
- [ ] Delete this checklist and all text above the line below when you're ready.

---

# Predy audit details
- Total Prize Pool: $100000 in USDC
  - HM awards: $79700 in USDC
  - (remove this line if there is no Analysis pool) Analysis awards: XXX XXX USDC (Notion: Analysis pool)
  - QA awards: $3300 in USDC
  - (remove this line if there is no Bot race) Bot Race awards: XXX XXX USDC (Notion: Bot Race pool)
 
  - Judge awards: $9900 in USDC
  - Lookout awards: XXX XXX USDC (Notion: Sum of Pre-sort fee + Pre-sort early bonus)
  - Scout awards: $500 in USDC
  - (this line can be removed if there is no mitigation) Mitigation Review: XXX XXX USDC (*Opportunity goes to top 3 backstage wardens based on placement in this audit who RSVP.*)
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2024-05-predy/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts May 24, 2024 20:00 UTC
- Ends June 14, 2024 20:00 UTC

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-05-predy/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._
## 🐺 C4: Begin Gist paste here (and delete this line)





# Scope

*See [scope.txt](https://github.com/code-423n4/2024-05-predy/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | SLOC  | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/PredyPool.sol | 1| **** | 209 | |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol<br>@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol<br>@solmate/src/utils/SafeTransferLib.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/PriceFeed.sol | 2| **** | 39 | |@solmate/src/utils/FixedPointMathLib.sol|
| /src/base/BaseHookCallback.sol | 1| **** | 18 | ||
| /src/base/BaseHookCallbackUpgradable.sol | 1| **** | 20 | |@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol|
| /src/base/BaseMarket.sol | 1| **** | 90 | |@solmate/src/auth/Owned.sol|
| /src/base/BaseMarketUpgradable.sol | 1| **** | 127 | ||
| /src/base/SettlementCallbackLib.sol | 1| **** | 153 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/ApplyInterestLib.sol | 1| **** | 65 | ||
| /src/libraries/Constants.sol | 1| **** | 18 | ||
| /src/libraries/DataType.sol | 1| **** | 34 | ||
| /src/libraries/InterestRateModel.sol | 1| **** | 24 | ||
| /src/libraries/PairLib.sol | 1| **** | 6 | ||
| /src/libraries/Perp.sol | 1| **** | 601 | |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-periphery/contracts/libraries/PositionKey.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@solmate/src/utils/SafeCastLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PerpFee.sol | 1| **** | 121 | |@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PositionCalculator.sol | 1| **** | 177 | |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/PremiumCurveModel.sol | 1| **** | 11 | ||
| /src/libraries/Reallocation.sol | 1| **** | 143 | |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/ScaledAsset.sol | 1| **** | 190 | |@solmate/src/utils/FixedPointMathLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/SlippageLib.sol | 1| **** | 41 | ||
| /src/libraries/Trade.sol | 1| **** | 108 | |@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/UniHelper.sol | 1| **** | 107 | |@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-periphery/contracts/libraries/PositionKey.sol|
| /src/libraries/VaultLib.sol | 1| **** | 47 | ||
| /src/libraries/logic/AddPairLogic.sol | 1| **** | 175 | |@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol<br>@openzeppelin/contracts/token/ERC20/IERC20.sol<br>@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol<br>@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol|
| /src/libraries/logic/LiquidationLogic.sol | 1| **** | 119 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/ReaderLogic.sol | 1| **** | 53 | ||
| /src/libraries/logic/ReallocationLogic.sol | 1| **** | 70 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/SupplyLogic.sol | 1| **** | 67 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/libraries/logic/TradeLogic.sol | 1| **** | 63 | ||
| /src/libraries/math/Bps.sol | 1| **** | 10 | ||
| /src/libraries/math/LPMath.sol | 1| **** | 118 | |@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@uniswap/v3-core/contracts/libraries/TickMath.sol<br>@uniswap/v3-core/contracts/libraries/FixedPoint96.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/math/Math.sol | 1| **** | 54 | |@uniswap/v3-core/contracts/libraries/FullMath.sol<br>@solmate/src/utils/FixedPointMathLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol|
| /src/libraries/orders/DecayLib.sol | 1| **** | 32 | ||
| /src/libraries/orders/OrderInfoLib.sol | 1| **** | 14 | ||
| /src/libraries/orders/Permit2Lib.sol | 1| **** | 23 | |@uniswap/permit2/src/interfaces/ISignatureTransfer.sol|
| /src/libraries/orders/ResolvedOrder.sol | 1| **** | 21 | ||
| /src/markets/L2Decoder.sol | 1| **** | 63 | ||
| /src/markets/gamma/ArrayLib.sol | 1| **** | 24 | ||
| /src/markets/gamma/GammaOrder.sol | 2| **** | 118 | ||
| /src/markets/gamma/GammaTradeMarket.sol | 1| **** | 347 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol<br>@uniswap/permit2/src/interfaces/IPermit2.sol|
| /src/markets/gamma/GammaTradeMarketL2.sol | 1| **** | 81 | ||
| /src/markets/gamma/GammaTradeMarketLib.sol | 1| **** | 179 | ||
| /src/markets/gamma/GammaTradeMarketWrapper.sol | 1| **** | 13 | ||
| /src/markets/gamma/L2GammaDecoder.sol | 1| **** | 76 | ||
| /src/markets/perp/PerpMarket.sol | 1| **** | 44 | ||
| /src/markets/perp/PerpMarketLib.sol | 1| **** | 171 | ||
| /src/markets/perp/PerpMarketV1.sol | 1| **** | 272 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@uniswap/permit2/src/interfaces/IPermit2.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol|
| /src/markets/perp/PerpOrder.sol | 1| **** | 63 | ||
| /src/markets/perp/PerpOrderV3.sol | 1| **** | 67 | ||
| /src/settlements/UniswapSettlement.sol | 1| **** | 52 | |@solmate/src/utils/SafeTransferLib.sol<br>@solmate/src/tokens/ERC20.sol<br>@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol<br>@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol|
| /src/tokenization/SupplyToken.sol | 1| **** | 21 | |@solmate/src/tokens/ERC20.sol|
| /src/types/GlobalData.sol | 1| **** | 90 | |@solmate/src/utils/SafeTransferLib.sol<br>@openzeppelin/contracts/utils/math/SafeCast.sol<br>@solmate/src/tokens/ERC20.sol|
| /src/types/LockData.sol | 1| **** | 10 | ||
| /src/vendors/AggregatorV3Interface.sol | ****| 1 | 14 | ||
| /src/vendors/IPyth.sol | ****| 1 | 11 | ||
| /src/vendors/IUniswapV3PoolOracle.sol | ****| 1 | 25 | ||
| **Totals** | **54** | **3** | **4909** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2024-05-predy/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./lib/permit2/lib/forge-gas-snapshot/src/GasSnapshot.sol |
| ./lib/permit2/lib/forge-gas-snapshot/src/test/SimpleOperations.sol |
| ./lib/permit2/lib/forge-gas-snapshot/src/test/SimpleOperationsGas.sol |
| ./lib/permit2/lib/forge-gas-snapshot/src/utils/UintString.sol |
| ./lib/permit2/lib/forge-gas-snapshot/test/GasSnapshot.t.sol |
| ./lib/permit2/script/DeployPermit2.s.sol |
| ./lib/permit2/src/AllowanceTransfer.sol |
| ./lib/permit2/src/EIP712.sol |
| ./lib/permit2/src/Permit2.sol |
| ./lib/permit2/src/PermitErrors.sol |
| ./lib/permit2/src/SignatureTransfer.sol |
| ./lib/permit2/src/interfaces/IAllowanceTransfer.sol |
| ./lib/permit2/src/interfaces/IDAIPermit.sol |
| ./lib/permit2/src/interfaces/IEIP712.sol |
| ./lib/permit2/src/interfaces/IERC1271.sol |
| ./lib/permit2/src/interfaces/IPermit2.sol |
| ./lib/permit2/src/interfaces/ISignatureTransfer.sol |
| ./lib/permit2/src/libraries/Allowance.sol |
| ./lib/permit2/src/libraries/Permit2Lib.sol |
| ./lib/permit2/src/libraries/PermitHash.sol |
| ./lib/permit2/src/libraries/SafeCast160.sol |
| ./lib/permit2/src/libraries/SignatureVerification.sol |
| ./lib/permit2/test/AllowanceTransferInvariants.t.sol |
| ./lib/permit2/test/AllowanceTransferTest.t.sol |
| ./lib/permit2/test/AllowanceUnitTest.sol |
| ./lib/permit2/test/CompactSignature.t.sol |
| ./lib/permit2/test/EIP712.t.sol |
| ./lib/permit2/test/NonceBitmap.t.sol |
| ./lib/permit2/test/Permit2Lib.t.sol |
| ./lib/permit2/test/SignatureTransfer.t.sol |
| ./lib/permit2/test/TypehashGeneration.t.sol |
| ./lib/permit2/test/actors/Permitter.sol |
| ./lib/permit2/test/actors/Spender.sol |
| ./lib/permit2/test/integration/Argent.t.sol |
| ./lib/permit2/test/integration/GnosisSafe.t.sol |
| ./lib/permit2/test/integration/MainnetToken.t.sol |
| ./lib/permit2/test/integration/tokens/DAI.t.sol |
| ./lib/permit2/test/integration/tokens/FeeOnTransferToken.t.sol |
| ./lib/permit2/test/integration/tokens/RebasingToken.t.sol |
| ./lib/permit2/test/integration/tokens/TooManyReturnBytesToken.t.sol |
| ./lib/permit2/test/integration/tokens/UNI.t.sol |
| ./lib/permit2/test/integration/tokens/USDC.t.sol |
| ./lib/permit2/test/integration/tokens/USDT.t.sol |
| ./lib/permit2/test/integration/tokens/WBTC.t.sol |
| ./lib/permit2/test/integration/tokens/ZRX.t.sol |
| ./lib/permit2/test/mocks/MockERC1155.sol |
| ./lib/permit2/test/mocks/MockERC20.sol |
| ./lib/permit2/test/mocks/MockERC721.sol |
| ./lib/permit2/test/mocks/MockFallbackERC20.sol |
| ./lib/permit2/test/mocks/MockHash.sol |
| ./lib/permit2/test/mocks/MockNonPermitERC20.sol |
| ./lib/permit2/test/mocks/MockNonPermitNonERC20WithDS.sol |
| ./lib/permit2/test/mocks/MockPermit2.sol |
| ./lib/permit2/test/mocks/MockPermit2Lib.sol |
| ./lib/permit2/test/mocks/MockPermitWithDS.sol |
| ./lib/permit2/test/mocks/MockSignatureVerification.sol |
| ./lib/permit2/test/utils/AddressBuilder.sol |
| ./lib/permit2/test/utils/AmountBuilder.sol |
| ./lib/permit2/test/utils/DeployPermit2.sol |
| ./lib/permit2/test/utils/DeployPermit2.t.sol |
| ./lib/permit2/test/utils/PermitSignature.sol |
| ./lib/permit2/test/utils/StructBuilder.sol |
| ./lib/permit2/test/utils/TokenProvider.sol |
| ./lib/v3-core/contracts/NoDelegateCall.sol |
| ./lib/v3-core/contracts/UniswapV3Factory.sol |
| ./lib/v3-core/contracts/UniswapV3Pool.sol |
| ./lib/v3-core/contracts/UniswapV3PoolDeployer.sol |
| ./lib/v3-core/contracts/interfaces/IERC20Minimal.sol |
| ./lib/v3-core/contracts/interfaces/IUniswapV3Factory.sol |
| ./lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol |
| ./lib/v3-core/contracts/interfaces/IUniswapV3PoolDeployer.sol |
| ./lib/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol |
| ./lib/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol |
| ./lib/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolErrors.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolEvents.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolOwnerActions.sol |
| ./lib/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol |
| ./lib/v3-core/contracts/libraries/BitMath.sol |
| ./lib/v3-core/contracts/libraries/FixedPoint128.sol |
| ./lib/v3-core/contracts/libraries/FixedPoint96.sol |
| ./lib/v3-core/contracts/libraries/FullMath.sol |
| ./lib/v3-core/contracts/libraries/Oracle.sol |
| ./lib/v3-core/contracts/libraries/Position.sol |
| ./lib/v3-core/contracts/libraries/SafeCast.sol |
| ./lib/v3-core/contracts/libraries/SqrtPriceMath.sol |
| ./lib/v3-core/contracts/libraries/SwapMath.sol |
| ./lib/v3-core/contracts/libraries/Tick.sol |
| ./lib/v3-core/contracts/libraries/TickBitmap.sol |
| ./lib/v3-core/contracts/libraries/TickMath.sol |
| ./lib/v3-core/contracts/libraries/TransferHelper.sol |
| ./lib/v3-core/contracts/libraries/UnsafeMath.sol |
| ./lib/v3-core/contracts/test/BitMathEchidnaTest.sol |
| ./lib/v3-core/contracts/test/BitMathTest.sol |
| ./lib/v3-core/contracts/test/FullMathEchidnaTest.sol |
| ./lib/v3-core/contracts/test/FullMathTest.sol |
| ./lib/v3-core/contracts/test/MockTimeUniswapV3Pool.sol |
| ./lib/v3-core/contracts/test/MockTimeUniswapV3PoolDeployer.sol |
| ./lib/v3-core/contracts/test/NoDelegateCallTest.sol |
| ./lib/v3-core/contracts/test/OracleEchidnaTest.sol |
| ./lib/v3-core/contracts/test/OracleTest.sol |
| ./lib/v3-core/contracts/test/SqrtPriceMathEchidnaTest.sol |
| ./lib/v3-core/contracts/test/SqrtPriceMathTest.sol |
| ./lib/v3-core/contracts/test/SwapMathEchidnaTest.sol |
| ./lib/v3-core/contracts/test/SwapMathTest.sol |
| ./lib/v3-core/contracts/test/TestERC20.sol |
| ./lib/v3-core/contracts/test/TestUniswapV3Callee.sol |
| ./lib/v3-core/contracts/test/TestUniswapV3ReentrantCallee.sol |
| ./lib/v3-core/contracts/test/TestUniswapV3Router.sol |
| ./lib/v3-core/contracts/test/TestUniswapV3SwapPay.sol |
| ./lib/v3-core/contracts/test/TickBitmapEchidnaTest.sol |
| ./lib/v3-core/contracts/test/TickBitmapTest.sol |
| ./lib/v3-core/contracts/test/TickEchidnaTest.sol |
| ./lib/v3-core/contracts/test/TickMathEchidnaTest.sol |
| ./lib/v3-core/contracts/test/TickMathTest.sol |
| ./lib/v3-core/contracts/test/TickOverflowSafetyEchidnaTest.sol |
| ./lib/v3-core/contracts/test/TickTest.sol |
| ./lib/v3-core/contracts/test/UniswapV3PoolSwapTest.sol |
| ./lib/v3-core/contracts/test/UnsafeMathEchidnaTest.sol |
| ./lib/v3-periphery/contracts/NonfungiblePositionManager.sol |
| ./lib/v3-periphery/contracts/NonfungibleTokenPositionDescriptor.sol |
| ./lib/v3-periphery/contracts/SwapRouter.sol |
| ./lib/v3-periphery/contracts/V3Migrator.sol |
| ./lib/v3-periphery/contracts/base/BlockTimestamp.sol |
| ./lib/v3-periphery/contracts/base/ERC721Permit.sol |
| ./lib/v3-periphery/contracts/base/LiquidityManagement.sol |
| ./lib/v3-periphery/contracts/base/Multicall.sol |
| ./lib/v3-periphery/contracts/base/PeripheryImmutableState.sol |
| ./lib/v3-periphery/contracts/base/PeripheryPayments.sol |
| ./lib/v3-periphery/contracts/base/PeripheryPaymentsWithFee.sol |
| ./lib/v3-periphery/contracts/base/PeripheryValidation.sol |
| ./lib/v3-periphery/contracts/base/PoolInitializer.sol |
| ./lib/v3-periphery/contracts/base/SelfPermit.sol |
| ./lib/v3-periphery/contracts/examples/PairFlash.sol |
| ./lib/v3-periphery/contracts/interfaces/IERC20Metadata.sol |
| ./lib/v3-periphery/contracts/interfaces/IERC721Permit.sol |
| ./lib/v3-periphery/contracts/interfaces/IMulticall.sol |
| ./lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol |
| ./lib/v3-periphery/contracts/interfaces/INonfungibleTokenPositionDescriptor.sol |
| ./lib/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol |
| ./lib/v3-periphery/contracts/interfaces/IPeripheryPayments.sol |
| ./lib/v3-periphery/contracts/interfaces/IPeripheryPaymentsWithFee.sol |
| ./lib/v3-periphery/contracts/interfaces/IPoolInitializer.sol |
| ./lib/v3-periphery/contracts/interfaces/IQuoter.sol |
| ./lib/v3-periphery/contracts/interfaces/IQuoterV2.sol |
| ./lib/v3-periphery/contracts/interfaces/ISelfPermit.sol |
| ./lib/v3-periphery/contracts/interfaces/ISwapRouter.sol |
| ./lib/v3-periphery/contracts/interfaces/ITickLens.sol |
| ./lib/v3-periphery/contracts/interfaces/IV3Migrator.sol |
| ./lib/v3-periphery/contracts/interfaces/external/IERC1271.sol |
| ./lib/v3-periphery/contracts/interfaces/external/IERC20PermitAllowed.sol |
| ./lib/v3-periphery/contracts/interfaces/external/IWETH9.sol |
| ./lib/v3-periphery/contracts/lens/Quoter.sol |
| ./lib/v3-periphery/contracts/lens/QuoterV2.sol |
| ./lib/v3-periphery/contracts/lens/TickLens.sol |
| ./lib/v3-periphery/contracts/lens/UniswapInterfaceMulticall.sol |
| ./lib/v3-periphery/contracts/libraries/AddressStringUtil.sol |
| ./lib/v3-periphery/contracts/libraries/BytesLib.sol |
| ./lib/v3-periphery/contracts/libraries/CallbackValidation.sol |
| ./lib/v3-periphery/contracts/libraries/ChainId.sol |
| ./lib/v3-periphery/contracts/libraries/HexStrings.sol |
| ./lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol |
| ./lib/v3-periphery/contracts/libraries/NFTDescriptor.sol |
| ./lib/v3-periphery/contracts/libraries/NFTSVG.sol |
| ./lib/v3-periphery/contracts/libraries/OracleLibrary.sol |
| ./lib/v3-periphery/contracts/libraries/Path.sol |
| ./lib/v3-periphery/contracts/libraries/PoolAddress.sol |
| ./lib/v3-periphery/contracts/libraries/PoolTicksCounter.sol |
| ./lib/v3-periphery/contracts/libraries/PositionKey.sol |
| ./lib/v3-periphery/contracts/libraries/PositionValue.sol |
| ./lib/v3-periphery/contracts/libraries/SafeERC20Namer.sol |
| ./lib/v3-periphery/contracts/libraries/SqrtPriceMathPartial.sol |
| ./lib/v3-periphery/contracts/libraries/TokenRatioSortOrder.sol |
| ./lib/v3-periphery/contracts/libraries/TransferHelper.sol |
| ./lib/v3-periphery/contracts/test/Base64Test.sol |
| ./lib/v3-periphery/contracts/test/LiquidityAmountsTest.sol |
| ./lib/v3-periphery/contracts/test/MockObservable.sol |
| ./lib/v3-periphery/contracts/test/MockObservations.sol |
| ./lib/v3-periphery/contracts/test/MockTimeNonfungiblePositionManager.sol |
| ./lib/v3-periphery/contracts/test/MockTimeSwapRouter.sol |
| ./lib/v3-periphery/contracts/test/NFTDescriptorTest.sol |
| ./lib/v3-periphery/contracts/test/NonfungiblePositionManagerPositionsGasTest.sol |
| ./lib/v3-periphery/contracts/test/OracleTest.sol |
| ./lib/v3-periphery/contracts/test/PathTest.sol |
| ./lib/v3-periphery/contracts/test/PeripheryImmutableStateTest.sol |
| ./lib/v3-periphery/contracts/test/PoolAddressTest.sol |
| ./lib/v3-periphery/contracts/test/PoolTicksCounterTest.sol |
| ./lib/v3-periphery/contracts/test/PositionValueTest.sol |
| ./lib/v3-periphery/contracts/test/SelfPermitTest.sol |
| ./lib/v3-periphery/contracts/test/TestCallbackValidation.sol |
| ./lib/v3-periphery/contracts/test/TestERC20.sol |
| ./lib/v3-periphery/contracts/test/TestERC20Metadata.sol |
| ./lib/v3-periphery/contracts/test/TestERC20PermitAllowed.sol |
| ./lib/v3-periphery/contracts/test/TestMulticall.sol |
| ./lib/v3-periphery/contracts/test/TestPositionNFTOwner.sol |
| ./lib/v3-periphery/contracts/test/TestUniswapV3Callee.sol |
| ./lib/v3-periphery/contracts/test/TickLensTest.sol |
| ./script/Counter.s.sol |
| ./src/interfaces/IFillerMarket.sol |
| ./src/interfaces/IHooks.sol |
| ./src/interfaces/IPredyPool.sol |
| ./src/interfaces/ISettlement.sol |
| ./src/interfaces/ISpotMarket.sol |
| ./src/interfaces/ISupplyToken.sol |
| ./src/lens/GammaTradeMarketQuoter.sol |
| ./src/lens/PerpMarketQuoter.sol |
| ./src/lens/PredyPoolQuoter.sol |
| ./src/lens/SpotMarketQuoter.sol |
| ./src/markets/spot/SpotMarket.sol |
| ./src/markets/spot/SpotMarketL2.sol |
| ./src/markets/spot/SpotOrder.sol |
| ./test/attack/AttackCallback.t.sol |
| ./test/feed/PriceFeed.t.sol |
| ./test/lens/GammaTradeMarketQuoter.t.sol |
| ./test/lens/PerpMarketQuoter.t.sol |
| ./test/lens/PredyPoolQuoter.t.sol |
| ./test/lens/Setup.t.sol |
| ./test/lens/SpotMarketQuoter.t.sol |
| ./test/libraries/InterestRateModel.t.sol |
| ./test/libraries/PairLib.t.sol |
| ./test/libraries/PerpFee.t.sol |
| ./test/libraries/PremiumCurveModel.t.sol |
| ./test/libraries/Reallocation.t.sol |
| ./test/libraries/SlippageLib.t.sol |
| ./test/libraries/math/LPMath.t.sol |
| ./test/libraries/math/Math.t.sol |
| ./test/libraries/orders/DecayLib.t.sol |
| ./test/libraries/perp/CalculateEntry.t.sol |
| ./test/libraries/perp/CalculateSqrtPerpOffset.t.sol |
| ./test/libraries/perp/ComputeRequiredAmounts.t.sol |
| ./test/libraries/perp/Perp.t.sol |
| ./test/libraries/perp/Reallocate.t.sol |
| ./test/libraries/perp/SettleUserBalance.t.sol |
| ./test/libraries/perp/Setup.t.sol |
| ./test/libraries/perp/UpdatePosition.t.sol |
| ./test/libraries/position/CalculateMinMargin.t.sol |
| ./test/libraries/position/PositionCalculator.t.sol |
| ./test/libraries/position/Setup.t.sol |
| ./test/libraries/scaled/Compound.t.sol |
| ./test/libraries/scaled/Setup.t.sol |
| ./test/libraries/scaled/UpdatePosition.t.sol |
| ./test/market/L2Decoder.t.sol |
| ./test/market/gamma/ArrayLib.t.sol |
| ./test/market/gamma/AutoClose.t.sol |
| ./test/market/gamma/AutoHedge.t.sol |
| ./test/market/gamma/Callback.t.sol |
| ./test/market/gamma/ExecLiquidationCall.t.sol |
| ./test/market/gamma/ExecuteOrder.t.sol |
| ./test/market/gamma/GammaTradeMarketLib.t.sol |
| ./test/market/gamma/GetUserPositions.t.sol |
| ./test/market/gamma/L2GammaDecoder.t.sol |
| ./test/market/gamma/Modify.t.sol |
| ./test/market/gamma/PredyLiquidationCallback.t.sol |
| ./test/market/gamma/Setup.t.sol |
| ./test/market/gamma/UpdateWhitelistFiller.t.sol |
| ./test/market/perp/Callback.t.sol |
| ./test/market/perp/ExecLiquidationCall.t.sol |
| ./test/market/perp/ExecuteOrderV3.t.sol |
| ./test/market/perp/GetUserPosition.t.sol |
| ./test/market/perp/PerpMarketLib.t.sol |
| ./test/market/perp/PredyLiquidationCallback.t.sol |
| ./test/market/perp/Setup.t.sol |
| ./test/market/spot/ExecuteL2Order.t.sol |
| ./test/market/spot/ExecuteOrder.t.sol |
| ./test/market/spot/Setup.t.sol |
| ./test/mocks/AttackCallbackContract.sol |
| ./test/mocks/DebugSettlement.sol |
| ./test/mocks/DebugSettlement2.sol |
| ./test/mocks/MockERC20.sol |
| ./test/mocks/MockPriceFeed.sol |
| ./test/mocks/TestSettlement.sol |
| ./test/mocks/TestTradeMarket.sol |
| ./test/pool/ExecLiquidationCall.t.sol |
| ./test/pool/ProtocolInsolvency.t.sol |
| ./test/pool/Reallocate.t.sol |
| ./test/pool/RegisterPair.t.sol |
| ./test/pool/SetOperator.t.sol |
| ./test/pool/Setup.t.sol |
| ./test/pool/Supply.t.sol |
| ./test/pool/Trade.t.sol |
| ./test/pool/UpdateAssetRiskParams.t.sol |
| ./test/pool/Withdraw.t.sol |
| ./test/utils/OrderValidatorUtils.sol |
| ./test/utils/PairStatusUtils.sol |
| ./test/utils/SigUtils.sol |
| Totals: 288 |

