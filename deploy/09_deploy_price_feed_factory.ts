import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const PYTH = '0xff1a0f4744e8582DF1aE09D5611b887B6a12925C'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()

  console.log(`Start deploying price feed with ${deployer}`)

  const { deploy } = deployments

  await deploy('PriceFeedFactory', {
    from: deployer,
    log: true,
    args: [PYTH]
  })
}

func.tags = ['price']

export default func
