const hre = require("hardhat");

async function main() {
  const LagoonToken = await hre.ethers.getContractFactory("LagoonToken");
  const lagoonToken = await LagoonToken.deploy("LagoonToken", "LGT", "YOUR_DEFAULT_LAGOON_ADDRESS");
  await lagoonToken.deployed();

  const lgnNft = await hre.ethers.getContractFactory("lgnNft");
  const lagoonNFT = await lgnNft.deploy();
  await lagoonNFT.deployed();

  console.log("LagoonToken deployed to:", lagoonToken.address);
  console.log("LagoonNFT deployed to:", lagoonNFT.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
