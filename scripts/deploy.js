const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy LagoonToken
  const LagoonToken = await hre.ethers.getContractFactory("LagoonToken");
  const lagoonToken = await LagoonToken.deploy("Lagoon", "LGN", deployer.address);
  await lagoonToken.waitForDeployment(); // Make sure the contract is deployed
  console.log("LagoonToken deployed to:", await lagoonToken.getAddress());

  // Deploy LagoonNFT
  console.log("Deploying LagoonNFT...");
  const LagoonNFT = await hre.ethers.getContractFactory("lgnNft");
  const lagoonNFT = await LagoonNFT.deploy();
  await lagoonNFT.waitForDeployment(); // Wait for deployment
  console.log("LagoonNFT deployed to:", await lagoonNFT.getAddress());

  // Deploy Proposal
  console.log("Deploying Proposal...");
  const Proposal = await hre.ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy(
    await lagoonNFT.getAddress(), // Address of deployed LagoonNFT
    await lagoonToken.getAddress() // Address of deployed LagoonToken
  );
  await proposal.waitForDeployment();
  console.log("Proposal deployed to:", await proposal.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
