predy6
=====

![](https://github.com/predyprotocol/predyx/workflows/test/badge.svg)

[![X](https://img.shields.io/twitter/url/https/twitter.com/cloudposse.svg?style=social&label=Follow%20Predy)](https://x.com/predyfinance)

## Overview

Predy is an on-chain exchange for trading Gamma and Perpetuals. It features Squart, which allows trading of perpetuals with gamma exposure covered by Uniswap V3.

- [Website](https://www.predy.finance)
- [Documentation](https://docs.predy.finance)
- [Blog](https://predyfinance.medium.com/)

## Development

```
# Installing dependencies
npm i
forge install

# Testing
forge test
```

## Architecture

This project features multiple market contracts centered around PredyPool. The market contracts define financial products and order types. Markets can leverage positions by utilizing PredyPool for token lending and borrowing. This architecture is highly scalable. For example, developers can create new futures exchanges with minimal code and gain leverage by connecting to PredyPool.

### PredyPool.sol

The process of shorting 1 WETH with a collateral of 100 USDC.

```mermaid
sequenceDiagram
autonumber
  actor Trader
  Trader->>Market: executeOrder(order)
  Market->>PredyPool: trade(tradeParams, settlementData)
  activate PredyPool
  PredyPool->>Market: predySettlementCallback(data, 1 WETH)
  activate Market
  Market->>PredyPool: take(to=Market, amount=1 WETH)
  activate PredyPool
  PredyPool-->>Market: transfer(amount=1 WETH)
  deactivate PredyPool
  Market->>UniswapSettlement: swapExactIn(data, amount=1 WETH)
  activate UniswapSettlement
  UniswapSettlement ->> SwapRouter: exactInput(amount=1 WETH)
  SwapRouter -->> UniswapSettlement: 1000 USDC
  UniswapSettlement-->>PredyPool: 1000 USDC
  UniswapSettlement-->>Market: 
  deactivate UniswapSettlement
  Market -->> PredyPool: 
  deactivate Market
  PredyPool->>Market: predyTradeAfterCallback(tradeParams, tradeResult)
  activate Market
  Trader-->>Market: transferFrom(from=Trader,to=Market,amount=100 USDC)
  Market-->>PredyPool: transfer(amount=100 USDC)
  deactivate Market
  PredyPool-->>Market: 
  deactivate PredyPool
  Market-->>Trader: 
```

### PerpMarket.sol

Limit order flow of PerpMarket.

```mermaid
sequenceDiagram
autonumber
  actor Trader
  actor Filler
  Trader->>Filler: eip712 signedOrder
  Filler->>PerpMarket: executeOrder(signedOrder, settlementData)
  activate PerpMarket
  PerpMarket->>Permit2: permitWitnessTransferFrom
  Permit2-->>PerpMarket: 
  PerpMarket->>PredyPool: trade(tradeParams, settlementData)
  activate PredyPool
  PredyPool-->>PerpMarket: returns tradeResult
  deactivate PredyPool
  PerpMarket-->>Filler: tradeResult
  deactivate PerpMarket
  Filler-->>Trader: 
```

### SpotMarket.sol

Market order flow of SpotMarket.

```mermaid
sequenceDiagram
autonumber
  actor Trader
  actor Filler
  Trader->>Filler: eip712 signedOrder
  Filler ->> SpotMarket: executeOrder(signedOrder, settlementData)
  activate SpotMarket
  SpotMarket ->> Permit2: permitWitnessTransferFrom
  activate Permit2
  Permit2 -->> SpotMarket: 
  deactivate Permit2
  SpotMarket ->> Settlement: swapExactIn(settlementData, baseTokenAmount)
  activate Settlement
  Settlement -->> SpotMarket: 
  deactivate Settlement
  SpotMarket -->> Filler: 
  deactivate SpotMarket
  Filler-->>Trader: 
```
