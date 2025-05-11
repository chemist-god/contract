const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Escrow Smart Contract", function () {
    let Escrow, escrow, depositor, beneficiary, arbiter;

    beforeEach(async function () {
        [depositor, beneficiary, arbiter] = await ethers.getSigners();
        Escrow = await ethers.getContractFactory("Escrow");
        escrow = await Escrow.deploy(beneficiary.address, arbiter.address, { value: ethers.parseEther("1") });
    });

    it("should deploy the contract and store the funds", async function () {
        expect(await escrow.amount()).to.equal(ethers.parseEther("1"));
        expect(await escrow.depositor()).to.equal(depositor.address);
    });

    it("should only allow arbiter to release funds", async function () {
        await expect(escrow.connect(beneficiary).releaseFunds()).to.be.revertedWith("Only arbiter can release funds");
        await escrow.connect(arbiter).releaseFunds();
        expect(await escrow.fundsReleased()).to.equal(true);
    });
});
