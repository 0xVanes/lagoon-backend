const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("lgnNft", function () {
    let lgnNft;
    let nft;
    let owner;
    let addr1;

    beforeEach(async function () {
        [owner, addr1] = await ethers.getSigners();
        lgnNft = await ethers.getContractFactory("lgnNft");
        nft = await lgnNft.deploy();
        await nft.deployed();
    });

    it("should mint a new NFT with the correct metadata", async function () {
        const lagoonType = "Gold";
        const tx = await nft.mintNFT(addr1.address, lagoonType);
        await tx.wait();

        const tokenId = 1;
        const tokenURI = await nft.tokenURI(tokenId);

        console.log("Token URI:", tokenURI);
        expect(tokenURI).to.include("data:application/json;base64,");
        expect(tokenURI).to.include(lagoonType);
    });

    it("should reject invalid lagoon types", async function () {
        await expect(nft.mintNFT(addr1.address, "InvalidType")).to.be.revertedWith("Invalid Lagoon type");
    });
});
