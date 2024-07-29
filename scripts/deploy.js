const hre = require("hardhat");

async function main() {
  const lgnNft = await ethers.deployContract("contracts/lgnNft.sol:lgnNft");
  const lagoonNft = await lgnNft.waitForDeployment();
  console.log("Deploying Contract...")
  console.log("Contract deployed to address:",  await lgnNft.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
