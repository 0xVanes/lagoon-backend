const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LagoonToken", function () {
  let LagoonToken, lagoonToken, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    LagoonToken = await ethers.getContractFactory("LagoonToken");
    lagoonToken = await LagoonToken.deploy("LagoonToken", "LAGOON", owner.address);
    await lagoonToken.deployed();
  });

  it("Should set the correct default lagoon address", async function () {
    expect(await lagoonToken.defaultLagoonAddress()).to.equal(owner.address);
  });

  it("Should mint initial tokens to the contract creator", async function () {
    const ownerBalance = await lagoonToken.balanceOf(owner.address);
    expect(ownerBalance).to.equal(ethers.utils.parseEther("1000"));
  });

  it("Should allow setting and getting lagoon recipient", async function () {
    await lagoonToken.connect(addr1).setUserLagoonRecipient(addr2.address);
    expect(await lagoonToken.getUserLagoonRecipient(addr1.address)).to.equal(addr2.address);
  });

  it("Should distribute tokens correctly on transfer", async function () {
    await lagoonToken.transfer(addr1.address, ethers.utils.parseEther("5"));
    const recipientBalance = await lagoonToken.balanceOf(addr1.address);
    expect(recipientBalance).to.equal(ethers.utils.parseEther("10")); // 10 LAGOON tokens distributed for 5 tokens transfer
  });

  it("Should prevent reentrancy in distributeTokens", async function () {
    await network.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // Increase time by 30 days
    await network.provider.send("evm_mine"); // Mine a block to reflect the time increase
    
    await lagoonToken.distributeTokens(addr1.address, ethers.utils.parseEther("100"));
    const recipientBalance = await lagoonToken.balanceOf(addr1.address);
    expect(recipientBalance).to.equal(ethers.utils.parseEther("10")); // 10 LAGOON tokens distributed

    await expect(
      lagoonToken.distributeTokens(addr1.address, ethers.utils.parseEther("100"))
    ).to.be.revertedWith("Token distribution not allowed yet");
  });
});
