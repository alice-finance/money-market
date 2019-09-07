const { constants, expectEvent, expectRevert, BN } = require("openzeppelin-test-helpers");
const { ZERO_ADDRESS } = constants;
const { expect } = require("chai");

let Base = artifacts.require("mock/base/BaseMock.sol");
let ReentrancyAttack = artifacts.require("mock/base/ReentrancyAttack.sol");
let InterestCalculator = artifacts.require("calculator/BaseInterestCalculator.sol");

contract("Base", function([owner1, owner2, notOwner, loan1, loan2]) {
  beforeEach(async function() {
    this.base = await Base.new();
  });

  context("owner", function() {
    it("should onlyOwner modifier only accept call from owner", async function() {
      expect(await this.base.owner()).to.be.equal(owner1);

      let result = await this.base.prohibitedFunction({ from: owner1 });

      expect(result).to.be.true;

      await expectRevert(this.base.prohibitedFunction({ from: notOwner }), "not called from owner");
    });

    it("should transfer ownership", async function() {
      expect(await this.base.owner()).to.be.equal(owner1);
      expect(await this.base.isOwner({ from: owner1 })).to.be.true;
      expect(await this.base.isOwner({ from: owner2 })).to.be.false;

      let { logs } = await this.base.transferOwnership(owner2, {
        from: owner1
      });

      expectEvent.inLogs(logs, "OwnershipTransferred", {
        previousOwner: owner1,
        newOwner: owner2
      });

      expect(await this.base.owner()).to.be.equal(owner2);
      expect(await this.base.isOwner({ from: owner1 })).to.be.false;
      expect(await this.base.isOwner({ from: owner2 })).to.be.true;
    });

    it("should not transfer ownership when not called from current owner", async function() {
      await this.base.transferOwnership(owner2, { from: owner1 });

      await expectRevert(this.base.transferOwnership(owner1, { from: owner1 }), "not called from owner");
    });
  });

  context("reentrance guard", function() {
    it("should guard from external call", async function() {
      const attacker = await ReentrancyAttack.new();
      await this.base.setCount(5);

      await expectRevert(this.base.guardedFunction1(attacker.address), "nonReentrant");
    });

    it("should guard local call", async function() {
      await this.base.setCount(5);
      await expectRevert(this.base.guardedFunction2(), "nonReentrant");
    });

    it("should guard local call with address ", async function() {
      await this.base.setCount(5);
      await expectRevert(this.base.guardedFunction3(), "nonReentrant");
    });
  });

  context("money market", function() {
    it("should get totalFunds and totalBorrows", async function() {
      expect(await this.base.totalFunds()).to.be.bignumber.equal(new BN(200));
      expect(await this.base.totalBorrows()).to.be.bignumber.equal(new BN(100));
    });

    it("should set and get SavingsInterestCalculator", async function() {
      const calculator1 = await InterestCalculator.new();
      const calculator2 = await InterestCalculator.new();

      expect(await this.base.savingsCalculator()).to.be.equal(ZERO_ADDRESS);

      let { logs } = await this.base.setSavingsCalculator(calculator1.address, {
        from: owner1
      });

      expectEvent.inLogs(logs, "SavingsCalculatorChanged", {
        previousCalculator: ZERO_ADDRESS,
        newCalculator: calculator1.address
      });

      expect(await this.base.savingsCalculator()).to.be.equal(calculator1.address);
      ({ logs } = await this.base.setSavingsCalculator(calculator2.address, { from: owner1 }));

      expectEvent.inLogs(logs, "SavingsCalculatorChanged", {
        previousCalculator: calculator1.address,
        newCalculator: calculator2.address
      });

      expect(await this.base.savingsCalculator()).to.be.equal(calculator2.address);
    });

    it("should not set SavingsInterestCalculator when address is ZERO_ADDRESS", async function() {
      await expectRevert(this.base.setSavingsCalculator(ZERO_ADDRESS, { from: owner1 }), "ZERO address");
    });

    it("should not set SavingsInterestCalculator when not called from owner", async function() {
      const calculator = await InterestCalculator.new();

      await expectRevert(
        this.base.setSavingsCalculator(calculator.address, { from: notOwner }),
        "not called from owner"
      );
    });

    it("should set and get Loan", async function() {
      expect(await this.base.loan()).to.be.equal(ZERO_ADDRESS);

      let { logs: logs } = await this.base.setLoan(loan1, { from: owner1 });

      expectEvent.inLogs(logs, "LoanChanged", {
        previousLoan: ZERO_ADDRESS,
        newLoan: loan1
      });

      expect(await this.base.loan()).to.be.equal(loan1);
      ({ logs } = await this.base.setLoan(loan2, { from: owner1 }));

      expectEvent.inLogs(logs, "LoanChanged", {
        previousLoan: loan1,
        newLoan: loan2
      });

      expect(await this.base.loan()).to.be.equal(loan2);
    });

    it("should not set LOAN when address is ZERO_ADDRESS", async function() {
      await expectRevert(this.base.setLoan(ZERO_ADDRESS, { from: owner1 }), "ZERO address");
    });

    it("should not set LOAN when not called from owner", async function() {
      await expectRevert(this.base.setLoan(loan1, { from: notOwner }), "not called from owner");
    });
  });
});
