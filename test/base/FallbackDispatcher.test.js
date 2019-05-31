const { expectRevert, BN } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

let Base = artifacts.require("contracts/mock/FallbackDispatcherMock.sol");
let ImplV1 = artifacts.require("contracts/mock/ImplV1.sol");
let ImplV2 = artifacts.require("contracts/mock/ImplV2.sol");
let InvalidImpl = artifacts.require("contracts/mock/InvalidImpl.sol");

contract("Base", function([owner]) {
  beforeEach(async function() {
    this.origBase = await Base.new();
  });

  context("without impl", function() {
    it("should fail to call undefined function", async function() {
      let base = await ImplV1.at(this.origBase.address);

      await expectRevert(base.increase(), "cannot dispatch function");
    });
  });

  context("with impl", function() {
    beforeEach(async function() {
      this.implV1 = await ImplV1.new();
      await this.origBase.setLoan(this.implV1.address, { from: owner });
      this.base = await ImplV1.at(this.origBase.address);
    });

    it("should call original functions", async function() {
      expect(await this.base.totalFunds()).to.be.bignumber.equal(new BN(200));
      expect(await this.base.totalBorrows()).to.be.bignumber.equal(new BN(100));
    });

    it("should call new impl v1 methods", async function() {
      expect(await this.base.loan()).to.be.equal(this.implV1.address);
      expect(await this.base.getValue()).to.be.bignumber.equal(new BN(0));

      await this.base.setValue(new BN(100));
      await this.base.increase();

      expect(await this.base.getValue()).to.be.bignumber.equal(new BN(101));

      await this.base.decrease();

      expect(await this.base.getValue()).to.be.bignumber.equal(new BN(100));
    });

    it("should fail to call undefined methods", async function() {
      const base = await InvalidImpl.at(this.origBase.address);

      await expectRevert.unspecified(base.invalidFunction());
    });

    context("with impl v2", function() {
      beforeEach(async function() {
        this.implV2 = await ImplV2.new();

        this.base = await ImplV1.at(this.origBase.address);
        await this.base.setValue(new BN(100));
        await this.base.setLoan(this.implV2.address);

        this.base = await ImplV2.at(this.origBase.address);
      });

      it("should call original functions", async function() {
        expect(await this.base.totalFunds()).to.be.bignumber.equal(new BN(200));
        expect(await this.base.totalBorrows()).to.be.bignumber.equal(new BN(100));
      });

      it("should call new impl v1 methods", async function() {
        expect(await this.base.loan()).to.be.equal(this.implV2.address);
        expect(await this.base.getValue()).to.be.bignumber.equal(new BN(100));

        await this.base.setValue(new BN(200));
        await this.base.increase();

        expect(await this.base.getValue()).to.be.bignumber.equal(new BN(201));

        await this.base.decrease();

        expect(await this.base.getValue()).to.be.bignumber.equal(new BN(200));
      });

      it("should call new impl v2 methods", async function() {
        expect(await this.base.loan()).to.be.equal(this.implV2.address);
        expect(await this.base.getValueV2()).to.be.bignumber.equal(new BN(0));

        await this.base.setValueV2(new BN(300));
        await this.base.increaseV2();

        expect(await this.base.getValue()).to.be.bignumber.equal(new BN(100));
        expect(await this.base.getValueV2()).to.be.bignumber.equal(new BN(301));

        await this.base.decreaseV2();

        expect(await this.base.getValue()).to.be.bignumber.equal(new BN(100));
        expect(await this.base.getValueV2()).to.be.bignumber.equal(new BN(300));
      });
    });
  });
});
