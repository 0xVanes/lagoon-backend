const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy LagoonToken
  const LagoonToken = await hre.ethers.getContractFactory("LagoonToken");
  const lagoonToken = await LagoonToken.deploy("LagoonToken", "LGN", deployer.address);
  await lagoonToken.waitForDeployment(); 
  console.log("LagoonToken deployed to:", await lagoonToken.getAddress());

  // Deploy LagoonNFT
  console.log("Deploying LagoonNFT...");
  const LagoonNFT = await hre.ethers.getContractFactory("lgnNft");
  const lagoonNFT = await LagoonNFT.deploy();
  await lagoonNFT.waitForDeployment(); 
  console.log("LagoonNFT deployed to:", await lagoonNFT.getAddress());

  // Deploy Proposal
  console.log("Deploying Proposal...");
  const Proposal = await hre.ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy(
    await lagoonNFT.getAddress(), 
    await lagoonToken.getAddress()
  );
  await proposal.waitForDeployment();
  const proposalContractAddress = await proposal.getAddress(); 
  console.log("Proposal deployed to:", proposalContractAddress);

  // Deploy Voting
  console.log("Deploying Voting...");
  const Voting = await hre.ethers.getContractFactory("Voting");
  const voting = await Voting.deploy(proposalContractAddress);
  //const voting = await Voting.deploy(proposalContractAddress, await lagoonToken.getAddress()); 
  await voting.waitForDeployment();
  console.log("Voting contract deployed to:", await voting.getAddress());

  // Deploy RealEstateAssetTokenization
  console.log("Deploying realEstateAssetTokenization...");
  const RealEstateAssetTokenization = await hre.ethers.getContractFactory("realEstateAssetTokenization");
  const realEstateAssetTokenization = await RealEstateAssetTokenization.deploy(deployer.address);
  await realEstateAssetTokenization.waitForDeployment();
  console.log("RealEstateAssetTokenization deployed to:", await realEstateAssetTokenization.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
