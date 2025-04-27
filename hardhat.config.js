require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    lisk: {
      url: "https://rpc.sepolia-api.lisk.com", // Lisk Sepolia RPC
      chainId: 4202,
      accounts: [`0x${process.env.PRIVATE_KEY}`], 
    },
  },
};
