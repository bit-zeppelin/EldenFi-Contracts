const { ethers, upgrades } = require("hardhat");

async function main() {

  // const EldenToken = await ethers.getContractFactory("EldenToken");
  // const eldenToken = await EldenToken.deploy(
  //   ethers.utils.parseEther("2000000"), // max supply
  //   ethers.utils.parseEther("1000000"), // initial rate
  //   ethers.utils.parseEther("0.1"), // emission rate
  //   "0x3745dfc48dCffBCD47AD6BA3B9a3Db66787002eC" // treasury address
  // );
  // await eldenToken.deployed()
  // console.log("EldenToken address: ", eldenToken.address)

  // const SEldenToken = await ethers.getContractFactory("SEldenToken");
  // const sEldenToken = await SEldenToken.deploy(
  //   "0x3FAa3fdfe5375E1b3a21eE4632Dba027D75AcFBB" // elden token address
  // );
  // await sEldenToken.deployed()
  // console.log("SEldenToken address: ", sEldenToken.address)

  // const EldenMaster = await ethers.getContractFactory("EldenMaster");
  // const eldenMaster = await EldenMaster.deploy(
  //   "0x3FAa3fdfe5375E1b3a21eE4632Dba027D75AcFBB", // elden token address
  //   1697832000 // start time
  // );
  // await eldenMaster.deployed()
  // console.log("EldenMaster address: ", eldenMaster.address)

  // const NFTPoolFactory = await ethers.getContractFactory("NFTPoolFactory");
  // const nftPoolFactory = await NFTPoolFactory.deploy(
  //   "0xb17c6B882fC9243875139d2324adD2EE6B508dA5", // master
  //   "0x3FAa3fdfe5375E1b3a21eE4632Dba027D75AcFBB", // elden token
  //   "0xa2658a432fc1FC56c2ff458fb48ec6cf826dcF47" // sElden token
  // );
  // await nftPoolFactory.deployed()
  // console.log("NFTPoolFactory address: ", nftPoolFactory.address)

  const YieldBooster = await ethers.getContractFactory("YieldBooster");
  const yieldBooster = await YieldBooster.deploy(
    "0xa2658a432fc1FC56c2ff458fb48ec6cf826dcF47" // sElden token
  );
  await yieldBooster.deployed()
  console.log("YieldBooster address: ", yieldBooster.address)

  const DividendsV2 = await ethers.getContractFactory("DividendsV2");
  const dividendsV2 = await DividendsV2.deploy(
    "0xa2658a432fc1FC56c2ff458fb48ec6cf826dcF47", // sElden token
    1697832000 // start time
  );
  await dividendsV2.deployed()
  console.log("DividendsV2 address: ", dividendsV2.address)

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
