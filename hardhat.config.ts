import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: "https://base-mainnet.g.alchemy.com/v2/-tArF-xoePkVYokh5ecNBiRqACYB-Cl7",
      }
    }
  }
};

export default config;
