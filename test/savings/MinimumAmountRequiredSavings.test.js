const { BN, constants, expectEvent, expectRevert } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const Savings = artifacts.require("mock/savings/MinimumAmountRequiredSavings.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");
const Calculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ZeroCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");
const MoneyMarket = artifacts.require("MoneyMarket.sol");

const { MAX_UINT256 } = constants;

const ZERO_BYTES = [0x00];
const MULTIPLIER = new BN(10).pow(new BN(18));
const MAX_AMOUNT = MULTIPLIER.mul(new BN("50000000"));
const AMOUNT_OVER = MULTIPLIER.mul(new BN(150));
const AMOUNT_UNDER = MULTIPLIER.mul(new BN(99));
const MINIMUM_SAVINGS_AMOUNT = MULTIPLIER.mul(new BN(100));

contract("MinimumAmountRequiredSavings", function([owner, user1, user2, user3, user4, not_allowed_user]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.calculator = await Calculator.new();
    this.zeroCalculator = await ZeroCalculator.new();

    this.users = [user1, user2, user3, user4, not_allowed_user];

    for (const [i, u] of this.users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: owner });
    }
  });

  beforeEach(async function() {
    this.base = await MoneyMarket.new(owner, this.dai.address, this.calculator.address);

    for (const [i, u] of this.users.slice(0, 4).entries()) {
      await this.dai.approve(this.base.address, MAX_UINT256, { from: u });
    }

    this.savings = await Savings.new();
    await this.base.setLoan(this.savings.address);
    this.market = await Savings.at(this.base.address);
    await this.market.setSavingsCalculator(this.zeroCalculator.address);
    await this.market.setSavingsCalculatorWithData(this.calculator.address, ZERO_BYTES);
    await this.market.setMinimumSavingsAmount(MINIMUM_SAVINGS_AMOUNT);
  });

  it("should get right information", async function() {
    expect(await this.market.minimumSavingsAmount()).to.be.bignumber.equal(MINIMUM_SAVINGS_AMOUNT);
  });

  it("should deposit ", async function() {
    let expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, AMOUNT_OVER);

    let { logs } = await this.market.depositWithData(AMOUNT_OVER, ZERO_BYTES, { from: user1 });

    expectEvent.inLogs(logs, "SavingsDeposited", {
      recordId: new BN(0),
      owner: user1,
      balance: AMOUNT_OVER,
      rate: expectedRate
    });

    let record = await this.market.getSavingsRecordWithData(new BN(0), ZERO_BYTES);
    expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT_OVER);
    expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

    expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, MINIMUM_SAVINGS_AMOUNT);
    ({ logs } = await this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, ZERO_BYTES, { from: user1 }));

    expectEvent.inLogs(logs, "SavingsDeposited", {
      recordId: new BN(1),
      owner: user1,
      balance: MINIMUM_SAVINGS_AMOUNT,
      rate: expectedRate
    });

    record = await this.market.getSavingsRecordWithData(new BN(1), ZERO_BYTES);
    expect(new BN(record.balance)).to.be.bignumber.equal(MINIMUM_SAVINGS_AMOUNT);
    expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

    const records = await this.market.getSavingsRecordsWithData(user1, ZERO_BYTES);
    const recordIds = await this.market.getSavingsRecordIdsWithData(user1, ZERO_BYTES);
    const eachRecords = await Promise.all(
      recordIds.map(async recordId => await this.market.getSavingsRecordWithData(recordId, ZERO_BYTES))
    );

    for (let i = 0; i < records.length; i++) {
      expect(records[i].id).to.be.equal(eachRecords[i].id);
      expect(records[i].owner).to.be.equal(eachRecords[i].owner);
      expect(records[i].interestRate).to.be.equal(eachRecords[i].interestRate);
      expect(records[i].balance).to.be.equal(eachRecords[i].balance);
      expect(records[i].principal).to.be.equal(eachRecords[i].principal);
      expect(records[i].initialTimestamp).to.be.equal(eachRecords[i].initialTimestamp);
    }
  });

  it("should not deposit when amount is not at least minimum amount", async function() {
    await expectRevert(
      this.market.depositWithData(AMOUNT_UNDER, ZERO_BYTES, { from: user1 }),
      "MinimumAmountRequiredSavings: savings amount should be at least minimum amount"
    );
  });
});
