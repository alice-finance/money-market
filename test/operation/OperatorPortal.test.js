const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const OperatorPortal = artifacts.require("operation/OperatorPortal.sol");
const Delegator = artifacts.require("mock/DelegatorMock.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");

const MULTIPLIER = new BN(10).pow(new BN(18));
const MINIMUM_STAKING_AMOUNT = MULTIPLIER.mul(new BN(25000000));
const PENDING_REMOVAL_DURATION = time.duration.days(7);
const MAX_AMOUNT = MULTIPLIER.mul(new BN(10000000000));
const AMOUNT1 = MULTIPLIER.mul(new BN(300000000));
const AMOUNT2 = MULTIPLIER.mul(new BN(350000000));
const AMOUNT3 = MULTIPLIER.mul(new BN(400000000));
const AMOUNT4 = MULTIPLIER.mul(new BN(450000000));
const AMOUNT_NOT_ENOUGH = MINIMUM_STAKING_AMOUNT.div(new BN(2));

contract("OperatorPortal", function([admin, operator1, operator2, operator3, operator4, notOperator, notAdmin]) {
  before(async function() {
    this.alice = await ERC20.new("Alice Token", "ALICE", 18);
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.bat = await ERC20.new("Basic Attention Token", "BAT", 18);
    this.rep = await ERC20.new("Augur", "REP", 18);
  });

  beforeEach(async function() {
    this.portal = await OperatorPortal.new(admin, this.alice.address, MINIMUM_STAKING_AMOUNT);

    await this.alice.mint(operator1, MAX_AMOUNT);
    await this.alice.mint(operator2, MAX_AMOUNT);
    await this.alice.mint(operator3, MAX_AMOUNT);
    await this.alice.mint(operator4, MAX_AMOUNT);

    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator1 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator2 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator3 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator4 });
  });

  it("should have valid configurations", async function() {
    expect(await this.portal.minimumStakingAmount()).to.be.bignumber.equal(MINIMUM_STAKING_AMOUNT);
    expect(await this.portal.pendingRemovalDuration()).to.be.bignumber.equal(PENDING_REMOVAL_DURATION);
  });

  describe("Stake", function() {
    it("should add stake", async function() {
      const { logs: logs1 } = await this.portal.addStake(this.bat.address, MINIMUM_STAKING_AMOUNT, { from: operator1 });

      expectEvent.inLogs(logs1, "StakeAdded", {
        asset: this.bat.address,
        account: operator1,
        amount: MINIMUM_STAKING_AMOUNT,
        stakeAmount: MINIMUM_STAKING_AMOUNT
      });

      expectEvent.inLogs(logs1, "OperatorAdded", {
        asset: this.bat.address,
        account: operator1
      });

      const { logs: logs5 } = await this.portal.addStake(this.bat.address, AMOUNT_NOT_ENOUGH, { from: operator1 });

      expectEvent.inLogs(logs5, "StakeAdded", {
        asset: this.bat.address,
        account: operator1,
        amount: AMOUNT_NOT_ENOUGH,
        stakeAmount: MINIMUM_STAKING_AMOUNT.add(AMOUNT_NOT_ENOUGH)
      });
    });

    it("should fail to stake when amount is less then minimum staking amount", async function() {
      await expectRevert(
        this.portal.addStake(this.bat.address, AMOUNT_NOT_ENOUGH, { from: operator1 }),
        "less than minimum staking amount"
      );
    });

    it("should remove stake", async function() {
      await this.portal.addStake(this.bat.address, MINIMUM_STAKING_AMOUNT.add(AMOUNT_NOT_ENOUGH), { from: operator1 });

      const { logs: logs1 } = await this.portal.removeStake(this.bat.address, AMOUNT_NOT_ENOUGH, { from: operator1 });

      expectEvent.inLogs(logs1, "StakeRemoved", {
        asset: this.bat.address,
        account: operator1,
        amount: AMOUNT_NOT_ENOUGH
      });

      let totalCount = PENDING_REMOVAL_DURATION.div(time.duration.days(1));
      let amountPerPeriod = AMOUNT_NOT_ENOUGH.div(new BN(totalCount));
      let withdrawableBalance = await this.portal.withdrawableBalanceOf(operator1);

      expect(withdrawableBalance).to.be.bignumber.equal(new BN(0));

      await time.increase(time.duration.days(1));
      withdrawableBalance = await this.portal.withdrawableBalanceOf(operator1);

      expect(withdrawableBalance).to.be.bignumber.equal(amountPerPeriod);

      const { logs: logs2 } = await this.portal.withdraw(amountPerPeriod, { from: operator1 });

      expectEvent.inLogs(logs2, "Withdrawn", {
        account: operator1,
        amount: amountPerPeriod,
        totalAmount: AMOUNT_NOT_ENOUGH,
        remainingAmount: AMOUNT_NOT_ENOUGH.sub(amountPerPeriod)
      });
    });
  });

  describe("Delegator", function() {
    beforeEach(async function() {
      await this.portal.addStake(this.bat.address, AMOUNT1, { from: operator1 });
      await this.portal.addStake(this.bat.address, AMOUNT2, { from: operator2 });
      await this.portal.addStake(this.bat.address, AMOUNT3, { from: operator3 });
      await this.portal.addStake(this.bat.address, AMOUNT4, { from: operator4 });

      await this.portal.addStake(this.rep.address, AMOUNT4, { from: operator1 });
      await this.portal.addStake(this.rep.address, AMOUNT3, { from: operator2 });
      await this.portal.addStake(this.rep.address, AMOUNT2, { from: operator3 });
      await this.portal.addStake(this.rep.address, AMOUNT1, { from: operator4 });
    });
  });
});
