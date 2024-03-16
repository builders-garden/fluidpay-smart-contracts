import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("FluidPay", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function fixDeploy() {
    // Contracts are deployed using the first signer/account by default
    const impersonatedSigner = await ethers.getImpersonatedSigner("0x1234567890123456789012345678901234567890");
    const wethHolder = await ethers.getImpersonatedSigner("0x4bb7f4c3d47c4b431cb0658f44287d52006fb506");

    console.log("Impersonated signer balance:", impersonatedSigner.address);

    const address = impersonatedSigner.address;

    console.log("Impersonated signer balance:", address);

    const FluidPaySingletonModule = await hre.ethers.getContractFactory("FluidPaySingletonModule");

    const usdc = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
    const usdcAavePool = "0xA238Dd80C259a72e81d7e4664a9801593F98d1c5";
    const pancakeSwapRouter = "0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb";
    const weth = "0x4200000000000000000000000000000000000006"

    // usdc on Base instance
    const usdcContract = await ethers.getContractAt("IERC20", usdc);
        
    const wethContract = await ethers.getContractAt("IERC20", weth);

    const pancakeSwapRouterContract = await ethers.getContractAt("PancakeRouter02", pancakeSwapRouter);

    const fluidPaySingletonModule = await FluidPaySingletonModule.deploy(address, usdc, usdcAavePool, pancakeSwapRouter, [weth], 1, 1, 50);

    return { fluidPaySingletonModule, address, usdc, weth, usdcAavePool, pancakeSwapRouter, wethHolder, usdcContract, wethContract, pancakeSwapRouterContract };
  }

  describe("Deployment", function () {
    it("Should deploy the contract", async function () {
      const { fluidPaySingletonModule, address, usdc, usdcAavePool, pancakeSwapRouter, usdcContract, wethContract,  } = await loadFixture(fixDeploy);
      expect(await fluidPaySingletonModule.owner()).to.equal(address);
      expect(await fluidPaySingletonModule.usdcAddress()).to.equal(usdc);
      expect(await fluidPaySingletonModule.usdcAavePool()).to.equal(usdcAavePool);
      expect(await fluidPaySingletonModule.pancakeSwapRouter()).to.equal(pancakeSwapRouter);
    });

    // wethHolder approves pancakeSwapRouter to spend weth
    it("Should swap on pancakeSwapRouter to spend weth", async function () {
      const { fluidPaySingletonModule, address, usdc, usdcAavePool, weth, pancakeSwapRouter, wethContract, wethHolder, pancakeSwapRouterContract } = await loadFixture(fixDeploy);
      const approveTx = await wethContract.connect(wethHolder).approve(pancakeSwapRouter, 10000000000000);
      // convert weth amount to 18 decimals
      const wethAmount = ethers.parseUnits("0.000001", 18);
      const minAmount = ethers.parseUnits("0", 18);
      console.log("wethAmount", wethAmount);
      // swap weth to usdc
      const swapTx = await pancakeSwapRouterContract.connect(wethHolder).swapExactTokensForTokens(wethAmount, minAmount, [weth, usdc], address, 999999999999999);
  });
});
});
