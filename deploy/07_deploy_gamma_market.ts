import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Filler, Permit2 } from '../addressList'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()

  console.log(`Start deploying gamma market with ${deployer}`)

  const { deploy } = deployments

  const PredyPool = await deployments.get('PredyPool')
  const PredyPoolQuoter = await deployments.get('PredyPoolQuoter')

  await deploy('GammaTradeMarketL2', {
    from: deployer,
    log: true,
    args: [],
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [PredyPool.address, Permit2, Filler, PredyPoolQuoter.address],
        },
      },
      proxyContract: "EIP173Proxy",
    },
  })

  const GammaTradeMarketL2 = await deployments.get('GammaTradeMarketL2')

  await deploy('GammaTradeMarketQuoter', {
    from: deployer,
    log: true,
    args: [GammaTradeMarketL2.address]
  })
}

func.tags = ['gamma'];

export default func
