const fs = require('fs')
const path = require('path')

const files = [
  'PredyPool',
  'ApplyInterestLib',
  'AddPairLogic',
  'LiquidationLogic',
  'ReallocationLogic',
  'SupplyLogic',
  'TradeLogic',
  'VaultLib',
  'Perp',
  'ScaledAsset'
]

const deployments = files.map(filename => fs.readFileSync(
  path.join(__dirname, '../out/', filename + '.sol/', filename + '.json')
).toString()).map(str => JSON.parse(str))

const abis = deployments.map(deployment => deployment.abi).reduce((abis, abi) => abis.concat(abi), [])

console.log(
  JSON.stringify(abis.filter(item => item.type === 'event'), undefined, 2)
)
