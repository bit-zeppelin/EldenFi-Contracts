import { ethers, network } from 'hardhat'
import { configs } from '@elden/common/config'
import { tryVerify } from '@elden/common/verify'
import { writeFileSync } from 'fs'

async function main() {
  // Remember to update the init code hash in SC for different chains before deploying
  const networkName = network.name
  const config = configs[networkName as keyof typeof configs]
  if (!config) {
    throw new Error(`No config found for network ${networkName}`)
  }

  const v3DeployedContracts = await import(`@elden/v3-core/deployments/${networkName}.json`)
  const v3PeripheryDeployedContracts = await import(`@elden/v3-periphery/deployments/${networkName}.json`)

  const stableSwapDeployedContracts = await import(`@elden/stableswap/deployments/${networkName}.json`)

  const eldenV3PoolDeployer_address = v3DeployedContracts.EldenV3PoolDeployer
  const eldenV3Factory_address = v3DeployedContracts.EldenV3Factory
  const positionManager_address = v3PeripheryDeployedContracts.NonfungiblePositionManager

  const smartRouterHelper = {
    address: '0x8650cc862764767a1E9Cad61Ae1F890dA0539D6c'
  }
  const smartRouter = {
    address: '0x33De4584Cee28D49597cDe5aEf5630d65B342B72'
  }
  const mixedRouteQuoterV1 = {
    address: '0x98299B9B449509aB15fCf13EA84b49e6AdDf91bb'
  }
  const quoterV2 = {
    address: '0xFC704a7792914ABe00238e0822B7F3B5967dEe96'
  }

  // /** SmartRouterHelper */
  // console.log('Deploying SmartRouterHelper...')
  // const SmartRouterHelper = await ethers.getContractFactory('SmartRouterHelper')
  // const smartRouterHelper = await SmartRouterHelper.deploy()
  // console.log('SmartRouterHelper deployed to:', smartRouterHelper.address)
  // // // await tryVerify(smartRouterHelper)

  // /** SmartRouter */
  // console.log('Deploying SmartRouter...')
  // const SmartRouter = await ethers.getContractFactory('SmartRouter', {
  //   libraries: {
  //     SmartRouterHelper: smartRouterHelper.address,
  //   },
  // })
  // const smartRouter = await SmartRouter.deploy(
  //   config.v2Factory,
  //   eldenV3PoolDeployer_address,
  //   eldenV3Factory_address,
  //   positionManager_address,
  //   stableSwapDeployedContracts.EldenStableSwapFactory,
  //   stableSwapDeployedContracts.EldenStableSwapTwoPoolInfo,
  //   config.WNATIVE
  // )
  // console.log('SmartRouter deployed to:', smartRouter.address)

  // await tryVerify(smartRouter, [
  //   config.v2Factory,
  //   eldenV3PoolDeployer_address,
  //   eldenV3Factory_address,
  //   positionManager_address,
  //   config.stableFactory,
  //   config.stableInfo,
  //   config.WNATIVE,
  // ])

  // /** MixedRouteQuoterV1 */
  // const MixedRouteQuoterV1 = await ethers.getContractFactory('MixedRouteQuoterV1', {
  //   libraries: {
  //     SmartRouterHelper: smartRouterHelper.address,
  //   },
  // })
  // const mixedRouteQuoterV1 = await MixedRouteQuoterV1.deploy(
  //   eldenV3PoolDeployer_address,
  //   eldenV3Factory_address,
  //   config.v2Factory,
  //   stableSwapDeployedContracts.EldenStableSwapFactory,
  //   config.WNATIVE
  // )
  // console.log('MixedRouteQuoterV1 deployed to:', mixedRouteQuoterV1.address)

  // await tryVerify(mixedRouteQuoterV1, [
  //   eldenV3PoolDeployer_address,
  //   eldenV3Factory_address,
  //   config.v2Factory,
  //   config.stableFactory,
  //   config.WNATIVE,
  // ])

  // /** QuoterV2 */
  // const QuoterV2 = await ethers.getContractFactory('QuoterV2', {
  //   libraries: {
  //     SmartRouterHelper: smartRouterHelper.address,
  //   },
  // })
  // const quoterV2 = await QuoterV2.deploy(eldenV3PoolDeployer_address, eldenV3Factory_address, config.WNATIVE)
  // console.log('QuoterV2 deployed to:', quoterV2.address)

  // await tryVerify(quoterV2, [eldenV3PoolDeployer_address, eldenV3Factory_address, config.WNATIVE])

  /** TokenValidator */
  const TokenValidator = await ethers.getContractFactory('TokenValidator', {
    libraries: {
      SmartRouterHelper: smartRouterHelper.address,
    },
  })
  const tokenValidator = await TokenValidator.deploy(config.v2Factory, positionManager_address)
  console.log('TokenValidator deployed to:', tokenValidator.address)

  // await tryVerify(tokenValidator, [config.v2Factory, positionManager_address])

  const contracts = {
    SmartRouter: smartRouter.address,
    SmartRouterHelper: smartRouterHelper.address,
    MixedRouteQuoterV1: mixedRouteQuoterV1.address,
    QuoterV2: quoterV2.address,
    TokenValidator: tokenValidator.address,
  }

  writeFileSync(`./deployments/${network.name}.json`, JSON.stringify(contracts, null, 2))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
