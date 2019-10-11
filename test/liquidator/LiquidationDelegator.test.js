const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const ZERO_ADDRESS = { constants };

const OperatorPortal = artifacts.require("operation/OperatorPortal.sol");
const Liquidator = artifacts.require("liquidator/LiquidationDelegator.sol");
const PriceSource = artifacts.require("mock/PriceSourceMock.sol");
const Loan = artifacts.require("mock/LoanMock.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");

const MULTIPLIER = new BN(10).pow(new BN(18));
const MINIMUM_STAKING_AMOUNT = MULTIPLIER.mul(new BN(25000000));
const PRICE_FEED_INTERVAL = time.duration.minutes(10);
const MAX_AMOUNT = MULTIPLIER.mul(new BN(10000000000));
const AMOUNT1 = MULTIPLIER.mul(new BN(300000000));
const AMOUNT2 = MULTIPLIER.mul(new BN(350000000));
const AMOUNT3 = MULTIPLIER.mul(new BN(400000000));
const AMOUNT4 = MULTIPLIER.mul(new BN(450000000));
const LOAN_AMOUNT1 = MULTIPLIER.mul(new BN(1000000));
const LOAN_AMOUNT2 = MULTIPLIER.mul(new BN(2000000));
const LOAN_AMOUNT3 = MULTIPLIER.mul(new BN(3000000));
const COL_AMOUNT1 = MULTIPLIER.mul(new BN(1000000));
const COL_AMOUNT2 = MULTIPLIER.mul(new BN(2000000));
const COL_AMOUNT3 = MULTIPLIER.mul(new BN(3000000));
const DAI_AMOUNT1 = MULTIPLIER.mul(new BN(4000000));
const DAI_AMOUNT2 = MULTIPLIER.mul(new BN(3000000));
const DAI_AMOUNT3 = MULTIPLIER.mul(new BN(2000000));
const DAI_AMOUNT4 = MULTIPLIER.mul(new BN(1000000));
const AMOUNT_NOT_ENOUGH = MINIMUM_STAKING_AMOUNT.div(new BN(2));
const PRICE1 = MULTIPLIER.mul(new BN(1001));
const PRICE2 = MULTIPLIER.mul(new BN(1002));
const PRICE3 = MULTIPLIER.mul(new BN(1003));
const PRICE4 = MULTIPLIER.mul(new BN(1004));

const getTimeslot = timestamp => {
  let timeslot = BN.isBN(timestamp) ? timestamp : new BN(timestamp);
  return timeslot.sub(timeslot.mod(new BN(600)));
};

contract("LiquidationDelegator", function([
  admin,
  operator1,
  operator2,
  operator3,
  operator4,
  user1,
  notOperator,
  notAdmin
]) {
  before(async function() {
    this.alice = await ERC20.new("Alice Token", "ALICE", 18);
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.bat = await ERC20.new("Basic Attention Token", "BAT", 18);
    this.rep = await ERC20.new("Augur", "REP", 18);
    this.portal = await OperatorPortal.new(admin, this.alice.address, MINIMUM_STAKING_AMOUNT);
    this.source = await PriceSource.new();
    this.loan = await Loan.new();

    await this.alice.mint(operator1, MAX_AMOUNT);
    await this.alice.mint(operator2, MAX_AMOUNT);
    await this.alice.mint(operator3, MAX_AMOUNT);
    await this.alice.mint(operator4, MAX_AMOUNT);

    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator1 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator2 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator3 });
    await this.alice.approve(this.portal.address, MAX_AMOUNT, { from: operator4 });

    await this.dai.mint(this.loan.address, MAX_AMOUNT);

    await this.bat.mint(this.loan.address, MAX_AMOUNT);
    await this.bat.mint(user1, MAX_AMOUNT);
    await this.bat.approve(this.loan.address, MAX_AMOUNT, { from: user1 });

    await this.portal.addStake(this.bat.address, AMOUNT1, { from: operator1 });
    await this.portal.addStake(this.bat.address, AMOUNT2, { from: operator2 });
    await this.portal.addStake(this.bat.address, AMOUNT3, { from: operator3 });
    await this.portal.addStake(this.bat.address, AMOUNT4, { from: operator4 });

    await this.portal.addStake(this.rep.address, AMOUNT4, { from: operator1 });
    await this.portal.addStake(this.rep.address, AMOUNT3, { from: operator2 });
    await this.portal.addStake(this.rep.address, AMOUNT2, { from: operator3 });
    await this.portal.addStake(this.rep.address, AMOUNT1, { from: operator4 });

    await this.loan.addLoan(LOAN_AMOUNT1, this.bat.address, COL_AMOUNT1, user1);
    await this.loan.addLoan(LOAN_AMOUNT2, this.bat.address, COL_AMOUNT2, user1);
    await this.loan.addLoan(LOAN_AMOUNT3, this.bat.address, COL_AMOUNT3, user1);

    await this.source.setPrice(this.bat.address, PRICE1);
  });

  beforeEach(async function() {
    this.liquidator = await Liquidator.new(
      admin,
      this.portal.address,
      this.dai.address,
      this.source.address,
      this.loan.address
    );
    await this.portal.addDelegator(this.liquidator.address);

    await this.dai.burnAll(operator1);
    await this.dai.burnAll(operator2);
    await this.dai.burnAll(operator3);
    await this.dai.burnAll(operator4);
    await this.dai.mint(operator1, DAI_AMOUNT1);
    await this.dai.mint(operator2, DAI_AMOUNT2);
    await this.dai.mint(operator3, DAI_AMOUNT3);
    await this.dai.mint(operator4, DAI_AMOUNT4);
    await this.dai.approve(this.liquidator.address, DAI_AMOUNT1, { from: operator1 });
    await this.dai.approve(this.liquidator.address, DAI_AMOUNT2, { from: operator2 });
    await this.dai.approve(this.liquidator.address, DAI_AMOUNT3, { from: operator3 });
    await this.dai.approve(this.liquidator.address, DAI_AMOUNT4, { from: operator4 });
  });

  it("should liquidate all loans on default", async function() {
    const { logs } = await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    console.log(logs);
    expect(false).to.be.true;
    // const result = await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
  });

  it("should penalize on liquidate", async function() {
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    await time.increase(time.duration.minutes(10));
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    await time.increase(time.duration.minutes(10));
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    await time.increase(time.duration.minutes(10));
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    expect(false).to.be.true;
  });
  it("should penalize late liquidation", async function() {
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    await time.increase(time.duration.minutes(30));
    await this.liquidator.liquidateAll(this.bat.address, { from: operator1 });
    expect(false).to.be.true;
  });
});
