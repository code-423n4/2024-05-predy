import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, ethers, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()

  console.log(`Start deploying modules with ${deployer}`)

  const { deploy } = deployments

  await deploy('AddPairLogic', {
    from: deployer,
    log: true,
  })

  await deploy('ReaderLogic', {
    from: deployer,
    log: true
  })

  await deploy('Trade', {
    from: deployer,
    log: true
  })

  const Trade = await deployments.get('Trade')

  await deploy('TradeLogic', {
    from: deployer,
    log: true,
    libraries: {
      Trade: Trade.address
    }
  })

  await deploy('LiquidationLogic', {
    from: deployer,
    log: true,
    libraries: {
      Trade: Trade.address
    }
  })

  await deploy('SupplyLogic', {
    from: deployer,
    log: true,
  })

  await deploy('ReallocationLogic', {
    from: deployer,
    log: true,
  })
}

func.tags = ['PredyPool'];

export default func
