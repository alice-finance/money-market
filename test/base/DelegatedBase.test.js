const { expectEvent, expectRevert, BN, constants } = require("openzeppelin-test-helpers");
const { expect } = require("chai");
const { ZERO_ADDRESS } = constants;

const Base = artifacts.require("contracts/mock/FallbackDispatcherMock.sol");
const Delegated0 = artifacts.require("contracts/mock/DelegatedMockV0.sol");
const Delegated1 = artifacts.require("contracts/mock/DelegatedMockV1.sol");
const Delegated2 = artifacts.require("contracts/mock/DelegatedMockV2.sol");

contract("DelegatedBase", function([admin, notAdmin]) {
  beforeEach(async function() {
    this.origBase = await Base.new();
  });

  context("without impl", function() {
    it("should fail to call undefined function", async function() {
      let base = await Delegated1.at(this.origBase.address);
      await expectRevert(base.increaseV1(), "cannot dispatch function");
    });
  });

  context("with impl", function() {
    beforeEach(async function() {
      this.impl = await Delegated1.new();
      await this.origBase.setLoan(this.impl.address, { from: admin });
      this.base = await Delegated1.at(this.origBase.address);
    });

    it("should call original functions", async function() {
      expect(await this.base.totalFunds()).to.be.bignumber.equal(new BN(200));
      expect(await this.base.totalBorrows()).to.be.bignumber.equal(new BN(100));
    });

    it("should initialize", async function() {
      await this.base.initialize({ from: admin });

      expect(await this.base.version()).to.be.bignumber.equal(new BN(1));
    });

    it("should call v1 functions", async function() {
      await this.base.initialize({ from: admin });
      const before = await this.base.getValueV1();
      await this.base.increaseV1();
      const after = await this.base.getValueV1();
      expect(after).to.be.bignumber.equal(before.add(new BN(1)));
    });

    it("should not call before initialized", async function() {
      await expectRevert(this.base.increaseV1(), "not initialized");
    });

    it("shoud not call v2 functions", async function() {
      await this.base.initialize({ from: admin });
      let base = await Delegated2.at(this.origBase.address);
      await expectRevert.unspecified(base.increaseV2());
    });

    it("should not initialize when not called from proxy", async function() {
      await expectRevert(this.impl.initialize({ from: admin }), "cannot call this contract directly");
    });

    it("should not initialize when not called from owner", async function() {
      await expectRevert(this.base.initialize({ from: notAdmin }), "not called from owner");
    });

    it("should not initialize twice", async function() {
      await this.base.initialize();
      await expectRevert(this.base.initialize({ from: admin }), "version already initialized");
    });

    it("should not initialize when version is ZERO", async function() {
      const impl0 = await Delegated0.new();
      await this.base.setLoan(impl0.address, { from: admin });
      this.base = await Delegated0.at(this.origBase.address);
      await expectRevert(this.base.initialize({ from: admin }), "version must be at least 1");
    });

    it("should not initialize when version is not continuous", async function() {
      const impl2 = await Delegated2.new();
      await this.base.setLoan(impl2.address, { from: admin });
      this.base = await Delegated2.at(this.origBase.address);
      await expectRevert(this.base.initialize({ from: admin }), "version must be continuous");
    });

    context("with impl v2", async function() {
      beforeEach(async function() {
        this.base = await Delegated1.at(this.origBase.address);
        await this.base.initialize({ from: admin });
        this.impl2 = await Delegated2.new();
        await this.origBase.setLoan(this.impl2.address, { from: admin });
        this.base = await Delegated2.at(this.origBase.address);
      });

      it("should initialize", async function() {
        expect(await this.base.version()).to.be.bignumber.equal(new BN(1));
        await this.base.initialize({ from: admin });

        expect(await this.base.version()).to.be.bignumber.equal(new BN(2));
      });

      it("should call v1 functions", async function() {
        await this.base.setValueV1(new BN(101));
        const before = await this.base.getValueV1();

        await this.base.initialize({ from: admin });
        await this.base.increaseV1();
        const after = await this.base.getValueV1();

        expect(after).to.be.bignumber.equal(before.add(new BN(1)));
        expect(after).to.be.bignumber.equal(new BN(102));
      });
    });
  });
});
