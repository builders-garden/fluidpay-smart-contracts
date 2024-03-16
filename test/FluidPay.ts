import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("FluidPay", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function fixDeploy() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const FluidPaySingletonModule = await hre.ethers.getContractFactory("FluidPaySingletonModule");

    const fluidPaySingletonModule = await FluidPaySingletonModule.deploy(owner, owner, owner, owner, [owner], 1, 1);

    return { fluidPaySingletonModule, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should deploy the contract", async function () {
      const { fluidPaySingletonModule, owner } = await loadFixture(fixDeploy);
      expect(await fluidPaySingletonModule.owner()).to.equal(owner);
      expect(await fluidPaySingletonModule.upkeep()).to.equal(owner);
      expect(await fluidPaySingletonModule.upkeep()).to.equal(owner);
      expect(await fluidPaySingletonModule.usdcAddress()).to.equal(owner);
      expect(await fluidPaySingletonModule.usdcAavePool()).to.equal(owner);
    });
  });
});
