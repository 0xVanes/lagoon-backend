const hre = require("hardhat");

async function main() {
  // Deploy LagoonToken
  const LagoonToken = await hre.ethers.getContractFactory("LagoonToken");
  const lagoonToken = await LagoonToken.deploy("LagoonToken", "LGT", "YOUR_DEFAULT_LAGOON_ADDRESS");
  await lagoonToken.deployed();
  console.log("LagoonToken deployed to:", lagoonToken.address);

  // Deploy LagoonNFT
  const lgnNft = await hre.ethers.getContractFactory("lgnNft");
  const lagoonNFT = await lgnNft.deploy();
  await lagoonNFT.deployed();
  console.log("LagoonNFT deployed to:", lagoonNFT.address);

  // Deploy Proposal
  const Proposal = await hre.ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy();
  await proposal.deployed();
  console.log("Proposal deployed to:", proposal.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
