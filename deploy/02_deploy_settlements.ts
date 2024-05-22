import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const SwapRouter02Address = '0xE592427A0AEce92De3Edee1F18E0157C05861564'
const QuoterV2Address = '0x61fFE014bA17989E743c5F6cB21bF9697530B21e'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deployer } = await getNamedAccounts()

  console.log(`Start deploying settlements with ${deployer}`)

  const { deploy } = deployments

  await deploy('UniswapSettlement', {
    from: deployer,
    log: true,
    args: [SwapRouter02Address, QuoterV2Address]
  })
}

func.tags = ['settlements'];

export default func
