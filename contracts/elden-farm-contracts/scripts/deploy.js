const { ethers, upgrades } = require("hardhat");

async function main() {

  const config = {
    treasuryAddress: "0x3745dfc48dCffBCD47AD6BA3B9a3Db66787002eC",
    startTime: 1698484735
  }


  const eldenToken = {
    address: '0x4815204D490F4300183E61A9C6b273D62191F7Cd'
  }
  // const EldenToken = await ethers.getContractFactory("EldenToken");
  // const eldenToken = await EldenToken.deploy(
  //   ethers.utils.parseEther("2000000"), // max supply
  //   ethers.utils.parseEther("1000000"), // initial rate
  //   ethers.utils.parseEther("0.1"), // emission rate
  //   config.treasuryAddress // treasury address
  // );
  // await eldenToken.deployed()
  // console.log("EldenToken address: ", eldenToken.address)

  // const eldenToken = {
  //   address: '0x4815204D490F4300183E61A9C6b273D62191F7Cd'
  // }

  // const SEldenToken = await ethers.getContractFactory("SEldenToken");
  // const sEldenToken = await SEldenToken.deploy(
  //   eldenToken.address // elden token address
  // );
  // await sEldenToken.deployed()
  // console.log("SEldenToken address: ", sEldenToken.address)

  // const EldenMaster = await ethers.getContractFactory("EldenMaster");
  // const eldenMaster = await EldenMaster.deploy(
  //   eldenToken.address, // elden token address
  //   config.startTime // start time
  // );
  // await eldenMaster.deployed()
  // console.log("EldenMaster address: ", eldenMaster.address)

  //   const eldenMaster = {
  //     address: '0x17621fB81F1B35A70477eC7145d7bD25e1A1EC49'
  //   }

  // const NFTPoolFactory = await ethers.getContractFactory("NFTPoolFactory");
  // const nftPoolFactory = await NFTPoolFactory.deploy(
  //   eldenMaster.address, // master
  //   eldenToken.address, // elden token
  //   sEldenToken.address // sElden token
  // );
  // await nftPoolFactory.deployed()
  // console.log("NFTPoolFactory address: ", nftPoolFactory.address)

  // const YieldBooster = await ethers.getContractFactory("YieldBooster");
  // const yieldBooster = await YieldBooster.deploy(
  //   sEldenToken.address // sElden token
  // );
  // await yieldBooster.deployed()
  // console.log("YieldBooster address: ", yieldBooster.address)
  const sEldenToken = {
    address: '0xc8B2e27B0E00eA9b7Cb07411f95d63a6E0b55c2b'
  }
  // const Dividends = await ethers.getContractFactory("Dividends");
  // const dividends = await Dividends.deploy(
  //   sEldenToken.address, // sElden token
  //   config.startTime // start time
  // );
  // await dividends.deployed()
  // console.log("Dividends address: ", dividends.address)

  // const Launchpad = await ethers.getContractFactory("Launchpad");
  // const launchpad = await Launchpad.deploy(
  //   sEldenToken.address, // sElden token
  // );
  // await launchpad.deployed()
  // console.log("Launchpad address: ", launchpad.address)




  const RunePoolFactory = await ethers.getContractFactory("RunePoolFactory");
  const runePoolFactory = await RunePoolFactory.deploy(
    eldenToken.address, 
    sEldenToken.address, 
    config.treasuryAddress, 
    config.treasuryAddress
  );
  await runePoolFactory.deployed()
  console.log("runePoolFactory address: ", runePoolFactory.address)



  // const RunePoolFactory = await ethers.getContractFactory("RunePoolFactory")
  // const runePoolFactory = await RunePoolFactory.deploy(
  //       eldenToken.address, 
  //       sEldenToken.address, 
  //       config.treasuryAddress, 
  //       config.treasuryAddress
  // )
  // await runePoolFactory.deployed()
  // console.log("RunePoolFactory Address: ", runePoolFactory.address)





  ///////////////////////////////////////////////////////////////
  //////////   Setting contracts
  //////////////////////////////////////////////////////////////
  // await eldenToken.updateAllocations(67,0)
  // await eldenToken.initializeEmissionStart(config.startTime)
  // await eldenToken.initializeMasterAddress(eldenMaster.address)

  // await sEldenToken.updateRedeemSettings(50,100,3600,86400,50)   /// for test
  // await sEldenToken.updateDividendsAddress(dividends.address)
  // await sEldenToken.updateDeallocationFee(dividends.address, 50)
  // await sEldenToken.updateDeallocationFee(yieldBooster.address, 50)
  // await sEldenToken.updateDeallocationFee(launchpad.address, 50)

  // await sEldenToken.updateTransferwhitelists(dividends.address)

  // await dividends.enableDistributedToken(sEldenToken.address)
  // await dividends.enableDistributedToken(ETH/USDT address)
  // await dividends.addDividendsToPending(sEldenToken.address, amount)
  // await dividends.addDividendsToPending(ETH/USDT address, amount)

  // await eldenMaster.setYieldBooster(yieldBooster.address)

  // await eldenMaster.add(NFTPool, allocpoint, update)

    // runePool.publish
  // runePool.addRewards(amounttoken1, amounttoken2)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
