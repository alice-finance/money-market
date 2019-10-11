const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const ZERO_ADDRESS = { constants };

const OperatorPortal = artifacts.require("operation/OperatorPortal.sol");
const PriceSource = artifacts.require("priceSource/OperatorPriceSource.sol");
const Delegator = artifacts.require("mock/DelegatorMock.sol");
const Exchange = artifacts.require("mock/ExchangeMock.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");

const MULTIPLIER = new BN(10).pow(new BN(18));
const MINIMUM_STAKING_AMOUNT = MULTIPLIER.mul(new BN(25000000));
const PRICE_FEED_INTERVAL = time.duration.minutes(10);
const MAX_AMOUNT = MULTIPLIER.mul(new BN(10000000000));
const AMOUNT1 = MULTIPLIER.mul(new BN(300000000));
const AMOUNT2 = MULTIPLIER.mul(new BN(350000000));
const AMOUNT3 = MULTIPLIER.mul(new BN(400000000));
const AMOUNT4 = MULTIPLIER.mul(new BN(450000000));
const AMOUNT_NOT_ENOUGH = MINIMUM_STAKING_AMOUNT.div(new BN(2));
const PRICE1 = MULTIPLIER.mul(new BN(1001));
const PRICE2 = MULTIPLIER.mul(new BN(1002));
const PRICE3 = MULTIPLIER.mul(new BN(1003));
const PRICE4 = MULTIPLIER.mul(new BN(1004));

const getTimeslot = timestamp => {
  let timeslot = BN.isBN(timestamp) ? timestamp : new BN(timestamp);
  return timeslot.sub(timeslot.mod(new BN(600)));
};

contract("OperatorPriceSource", function([admin, operator1, operator2, operator3, operator4, notOperator, notAdmin]) {
  before(async function() {
    this.alice = await ERC20.new("Alice Token", "ALICE", 18);
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.bat = await ERC20.new("Basic Attention Token", "BAT", 18);
    this.rep = await ERC20.new("Augur", "REP", 18);
    this.exchange = await Exchange.new();
  });

  beforeEach(async function() {
    this.portal = await OperatorPortal.new(admin, this.alice.address, MINIMUM_STAKING_AMOUNT);
    this.source = await PriceSource.new(admin, this.portal.address, this.dai.address, this.exchange.address);
    await this.portal.addDelegator(this.source.address);

    await this.alice.mint(operator1, MAX_AMOUNT);
    await this.alice.mint(operator2, MAX_AMOUNT);
    await this.alice.mint(operator3, MAX_AMOUNT);
    await this.alice.mint(operator4, MAX_AMOUNT);

    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator1 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator2 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator3 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator4 });

    await this.portal.addStake(this.bat.address, AMOUNT1, { from: operator1 });
    await this.portal.addStake(this.bat.address, AMOUNT2, { from: operator2 });
    await this.portal.addStake(this.bat.address, AMOUNT3, { from: operator3 });
    await this.portal.addStake(this.bat.address, AMOUNT4, { from: operator4 });

    await this.portal.addStake(this.rep.address, AMOUNT4, { from: operator1 });
    await this.portal.addStake(this.rep.address, AMOUNT3, { from: operator2 });
    await this.portal.addStake(this.rep.address, AMOUNT2, { from: operator3 });
    await this.portal.addStake(this.rep.address, AMOUNT1, { from: operator4 });
  });

  it("should post price", async function() {
    const now = await time.latest();
    const timeslot = getTimeslot(now);

    const { logs } = await this.source.postPrice(this.bat.address, now, PRICE1, { from: operator1 });
    expectEvent.inLogs(logs, "PriceReported", {
      asset: this.bat.address,
      reporter: operator1,
      timeslot: timeslot,
      price: PRICE1
    });
  });

  it("should validate previous price slot", async function() {
    let now = await time.latest();
    const previousTimeslot = getTimeslot(now);

    await this.exchange.setPrice(this.bat.address, PRICE1);
    await this.source.postPrice(this.bat.address, now, PRICE1, { from: operator1 });
    await this.source.postPrice(this.bat.address, now, PRICE2, { from: operator2 });
    await this.source.postPrice(this.bat.address, now, PRICE3, { from: operator3 });
    await this.source.postPrice(this.bat.address, now, PRICE4, { from: operator4 });

    await time.increase(PRICE_FEED_INTERVAL);
    now = await time.latest();
    const timeslot = getTimeslot(now);

    const { logs } = await this.source.postPrice(this.bat.address, now, PRICE2, { from: operator2 });

    expectEvent.inLogs(logs, "PriceAccepted", {
      asset: this.bat.address,
      reporter: operator4,
      timeslot: previousTimeslot,
      price: PRICE4
    });

    expect(await this.source.getPrice(this.bat.address, previousTimeslot)).to.be.bignumber.equal(PRICE4);
    expect(await this.source.getLastPrice(this.bat.address)).to.be.bignumber.equal(PRICE4);
  });

  it.only("should slash if nobody post price", async function() {
    let now = await time.latest();
    const slot1 = getTimeslot(now);
    const slot0 = slot1.sub(PRICE_FEED_INTERVAL);

    await this.exchange.setPrice(this.bat.address, PRICE1);
    await this.source.postPrice(this.bat.address, now, PRICE1, { from: operator1 });
    await this.source.postPrice(this.bat.address, now, PRICE2, { from: operator2 });
    await this.source.postPrice(this.bat.address, now, PRICE3, { from: operator3 });
    await this.source.postPrice(this.bat.address, now, PRICE4, { from: operator4 });

    await time.increase(PRICE_FEED_INTERVAL);
    now = await time.latest();
    const slot2 = getTimeslot(now);

    await time.increase(PRICE_FEED_INTERVAL);
    now = await time.latest();
    const slot3 = getTimeslot(now);

    await time.increase(PRICE_FEED_INTERVAL);
    now = await time.latest();
    const slot4 = getTimeslot(now);

    const { tx, logs } = await this.source.postPrice(this.bat.address, now, PRICE2, { from: operator2 });

    expect(await this.source.getPrice(this.bat.address, slot0)).to.be.bignumber.equal(PRICE1);
    expect(await this.source.getPrice(this.bat.address, slot1)).to.be.bignumber.equal(PRICE4);
    expect(await this.source.getPrice(this.bat.address, slot2)).to.be.bignumber.equal(PRICE4);
    expect(await this.source.getPrice(this.bat.address, slot3)).to.be.bignumber.equal(PRICE4);
    expect(await this.source.getLastPrice(this.bat.address)).to.be.bignumber.equal(PRICE4);

    // all operators should slashed their alice twice - slot 2 and 3 doesn't have any price posted
    // prettier-ignore
    {
      const rate = await this.source.penaltyRate();
      let op1 = AMOUNT1;
      let op2 = AMOUNT2;
      let op3 = AMOUNT3;
      let op4 = AMOUNT4;
      let total = op1.add(op2).add(op3).add(op4);

      op1 = op1.sub(op1.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op2 = op2.sub(op2.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op3 = op3.sub(op3.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op4 = op4.sub(op4.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      total = op1.add(op2).add(op3).add(op4);
      op1 = op1.sub(op1.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op2 = op2.sub(op2.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op3 = op3.sub(op3.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));
      op4 = op4.sub(op4.mul(MULTIPLIER).div(total).mul(rate).div(MULTIPLIER));

      expect(await this.portal.stakeOf(this.bat.address, operator1)).to.be.bignumber.equal(op1);
      expect(await this.portal.stakeOf(this.bat.address, operator2)).to.be.bignumber.equal(op2);
      expect(await this.portal.stakeOf(this.bat.address, operator3)).to.be.bignumber.equal(op3);
      expect(await this.portal.stakeOf(this.bat.address, operator4)).to.be.bignumber.equal(op4);
    }
  });
});
