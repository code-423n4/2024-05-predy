import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const uniswapFactory = '0x1F98431c8aD98523631AE4a59f267346ea31F984'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers, network } = hre
  const { deployer } = await getNamedAccounts()
  const { deploy } = deployments

  console.log(`Start deploying PredyPool with ${deployer}`)

  const AddPairLogic = await deployments.get('AddPairLogic')
  const ReallocationLogic = await deployments.get('ReallocationLogic')
  const LiquidationLogic = await deployments.get('LiquidationLogic')
  const ReaderLogic = await deployments.get('ReaderLogic')
  const SupplyLogic = await deployments.get('SupplyLogic')
  const TradeLogic = await deployments.get('TradeLogic')

  await deploy('PredyPool', {
    from: deployer,
    args: [],
    libraries: {
      ReallocationLogic: ReallocationLogic.address,
      LiquidationLogic: LiquidationLogic.address,
      ReaderLogic: ReaderLogic.address,
      AddPairLogic: AddPairLogic.address,
      SupplyLogic: SupplyLogic.address,
      TradeLogic: TradeLogic.address,
    },
    log: true,
    proxy: {
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            uniswapFactory
          ],
        },
      },
      proxyContract: "EIP173Proxy",
    },
  })
}

func.tags = ['PredyPool'];

export default func
