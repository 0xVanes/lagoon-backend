require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const {PRIVATE_KEY } = process.env;

module.exports = {
   solidity: "0.8.20",
   defaultNetwork: "haqqtestedge",
   networks: {
     hardhat: {},
     haqqtestedge: {
      url: "https://rpc.eth.testedge2.haqq.network", 
      accounts: [`0x${PRIVATE_KEY}`] 
    },
   },
};