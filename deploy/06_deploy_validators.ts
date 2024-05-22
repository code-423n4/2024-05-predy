import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()

  console.log(`Start deploying validators market with ${deployer}`)

  const { deploy } = deployments

  await deploy('DutchOrderValidator', {
    from: deployer,
    log: true,
  })

  await deploy('GeneralDutchOrderValidator', {
    from: deployer,
    log: true,
  })

  await deploy('LimitOrderValidator', {
    from: deployer,
    log: true,
  })
}

func.tags = ['validators'];

export default func
