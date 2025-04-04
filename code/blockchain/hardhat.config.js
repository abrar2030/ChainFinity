require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    arbitrum: {
      url: process.env.ARB_RPC_URL,
      accounts: [process.env.DEPLOYER_KEY]
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL,
      accounts: [process.env.DEPLOYER_KEY]
    }
  },
  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ARBISCAN_KEY,
      polygon: process.env.POLYGONSCAN_KEY
    }
  },
  sourcify: {
    enabled: true
  }
};