import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // for mainnet
    "scroll-mainnet": {
      url: "https://rpc.scroll.io",
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 10000000000,
    },
    // for testnet
    "scroll-sepolia": {
      url: "https://sepolia-rpc.scroll.io",
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 10000000000,
    },
    // for local dev environment
    "scroll-local": {
      url: "http://localhost:8545",
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: {
      "scroll-sepolia": "abc",
      "scroll-mainnet": "abc",
    },
    customChains: [
      {
        network: "scroll-mainnet",
        chainId: 534352,
        urls: {
          apiURL: "https://api.scrollscan.dev/api",
          browserURL: "https://scrollscan.dev/",
        },
      },
      {
        network: "scroll-sepolia",
        chainId: 534351,
        urls: {
          apiURL: "https://sepolia-blockscout.scroll.io/api",
          browserURL: "https://sepolia-blockscout.scroll.io/",
        },
      },
    ],
  },
  defaultNetwork: "scroll-sepolia",
};

export default config;
