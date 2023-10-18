import { ethers } from "hardhat";

async function main() {
  // const factory = await ethers.deployContract("EldenFiFactory", [
  //   "0x9FC429E0fBE28D355AE2C2e09f5F4c543aa4d2B2",
  // ]);
  // await factory.waitForDeployment();
  // console.log("factory contract deployed at " + factory.target);

  const factory_target = "0x06895109dE5c970D8eC777d2Ab87B0966Fee6207";

  const weth = "0x5300000000000000000000000000000000000004";
  // const router = await ethers.deployContract("EldenFiRouter", [
  //   factory_target,
  //   weth,
  // ]);
  // await router.waitForDeployment();
  // console.log("router contract deployed at " + router.target);

  const router_target = "0xBa09aa880c5FB989EF7ADf65bF9bf123cE16c5CB";
  const owner = "0x9FC429E0fBE28D355AE2C2e09f5F4c543aa4d2B2";
  const elden = await ethers.deployContract("EldenToken", [
    "2000000000000000000000000",
    "1000000000000000000000000",
    "188583676300000",
    owner,
  ]);
  await elden.waitForDeployment();
  console.log("elden contract " + elden.target);

  const xElden = await ethers.deployContract("EldenStakeToken", [elden.target]);
  await xElden.waitForDeployment();
  console.log("xElden contract " + xElden.target);

  const master = await ethers.deployContract("EldenFiMaster", [
    elden.target,
    "1697531547",
  ]);
  await master.waitForDeployment();
  console.log("master contract " + master.target);

  const nftPoolFactory = await ethers.deployContract("NFTPoolFactory", [
    master.target,
    elden.target,
    xElden.target,
  ]);
  await nftPoolFactory.waitForDeployment();
  console.log("NFTPoolFactory contract " + nftPoolFactory.target);

  const positionHelper = await ethers.deployContract("PositionHelper", [
    router_target,
    weth,
  ]);
  await positionHelper.waitForDeployment();
  console.log("positionHelper contract " + positionHelper.target);

  const raitoPoolFactory = await ethers.deployContract("RaitoPoolFactory", [
    elden.target,
    xElden.target,
    owner,
    owner,
  ]);
  await raitoPoolFactory.waitForDeployment();
  console.log("raitoPoolFactory contract " + raitoPoolFactory.target);

  // const yieldBooster = await ethers.deployContract('YieldBooster', [xElden.target]);
  // await yieldBooster.waitForDeployment();
  // console.log('yieldBooster contract ' + yieldBooster.target);

  // const dividEnd = await ethers.deployContract('Dividends', [xElden.target, "1691020800"]);
  // await dividEnd.waitForDeployment();
  // console.log('dividEnd contract ' + dividEnd.target);

  // const usdcContract = await ethers.deployContract('FiatTokenV2_1');
  // await usdcContract.waitForDeployment();
  // console.log('USDC contract ' + usdcContract.target);

  const dividendsContract = await ethers.deployContract("Dividends", [
    xElden.target,
    "1697531547",
  ]);
  await dividendsContract.waitForDeployment();
  console.log(
    "dividends contract " +
      dividendsContract.target +
      " with params " +
      xElden.target +
      " " +
      "1697531547"
  );

  const fairAuctionContract = await ethers.deployContract("FairAuction", [
    elden.target,
    xElden.target,
    "0x5300000000000000000000000000000000000004",
    "0x0000000000000000000000000000000000000000",
    "1697963547",
    "1698049947",
    "0x9FC429E0fBE28D355AE2C2e09f5F4c543aa4d2B2",
    "6000000000000000000",
    "4000000000000000000",
    "100000000000000000",
    "300000000000000000",
    "0",
  ]);
  await fairAuctionContract.waitForDeployment();
  console.log("fairAuctionContract contract " + fairAuctionContract.target);

  const yieldBoosterContract = await ethers.deployContract("YieldBooster", [
    xElden.target,
  ]);
  await yieldBoosterContract.waitForDeployment();
  console.log("yieldBoosterContract contract " + yieldBoosterContract.target);

  const launchPadContract = await ethers.deployContract("Launchpad", [
    xElden.target,
  ]);
  await launchPadContract.waitForDeployment();
  console.log("launchPadContract contract " + launchPadContract.target);

  const multicall = await ethers.deployContract("Multicall2");
  await multicall.waitForDeployment();
  console.log("Multicall2 contract " + multicall.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
