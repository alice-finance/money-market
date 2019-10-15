const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const MoneyMarket = artifacts.require("MoneyMarket");
const Loan = artifacts.require("loan/Loan");
const ERC20 = artifacts.require("mock/ERC20Mock.sol");
const ERC20Invalid = artifacts.require("mock/ERC20MockInvalid.sol");
const ERC20Fails = artifacts.require("mock/ERC20MockFails.sol");
const AssetRegistry = artifacts.require("mock/AssetRegistryMock.sol");
const PriceSource = artifacts.require("mock/PriceSourceMock.sol");
const OperatorPortal = artifacts.require("mock/OperatorPortal.sol");
const LoanCalculator = artifacts.require("calculator/LoanInterestCalculatorV1.sol");
const SavingsCalculator = artifacts.require("calculator/SavingsInterestCalculatorV2.sol");

const { MAX_UINT256 } = constants;

const ZERO = new BN(0);
const MULTIPLIER = new BN(10).pow(new BN(18));
const MAX_AMOUNT = MULTIPLIER.mul(new BN("50000000"));
const AMOUNT1 = MULTIPLIER.mul(new BN(100));
const AMOUNT2 = MULTIPLIER.mul(new BN(150));
const AMOUNT3 = MULTIPLIER.mul(new BN(200));
const AMOUNTS = [AMOUNT1, AMOUNT2, AMOUNT3];
const WITHDRAW_AMOUNT = MULTIPLIER.mul(new BN(50));
const DAYS_10 = time.duration.days(10);
const DAYS_30 = time.duration.days(30);
const DAYS_365 = time.duration.days(365);
const DAYS = [DAYS_10, DAYS_30, DAYS_365];

contract("Loan", function([owner, user1, user2, user3, not_allowed_user, insufficient_user]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.collateral = await ERC20.new("COLLATERAL Token", "CLT", 18);
    this.notCollateral = await ERC20.new("NOT COLLATERAL TOKEN", "NCLT", 18);

    this.loanCalculator = await LoanCalculator.new();
    this.savingsCalculator = await SavingsCalculator.new();

    this.users = [user1, user2, user3, not_allowed_user];

    for (const [i, u] of this.users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: owner });
    }
  });

  beforeEach(async function() {
    this.market = await MoneyMarket.new(owner, this.dai.address, this.savingsCalculator.address);
    this.loan = await Loan.new();
    await this.market.setLoan(this.loan.address);
    this.market = await Loan.at(this.market.address);

    for (const [i, u] of this.users.slice(0, 3).entries()) {
      await this.dai.approve(this.market.address, MAX_UINT256, { from: u });
    }
  });

  it("simple test", async function() {
    expect(await this.market.loan()).to.be.equal(this.loan.address);

    console.log(await this.market.getLoanInterestRate);
  });

  context("borrow", function() {
    it("should borrow asset", async function() {
      let expectedRate = await this.loanCalculator.getInterestRate(0, 0, MULTIPLIER);
    });

    context("should fail", function() {
      it("when given collateral is not registered");
      it("when amount or collateralAmount is ZERO");
      it("when user does not approved enough collateral");
      it("when user does not have enough collateral");
      it("when collateral rate is insufficient");
    });
  });

  context("repay", function() {
    it("should repay");

    context("should fail", function() {
      it("when loan is invalid");
      it("when amount is ZERO");
      it("when amount is greater then remaining balance");
      it("when user does not approved enough asset");
      it("when user does not have enough asset");
    });
  });

  context("supply or withdraw collateral", function() {
    it("should supply");
    it("should withdraw");

    context("should fail supply", function() {
      it("when loan is invalid");
      it("when collateralAmount is ZERO");
      it("when user does not approved enough collateral");
      it("when user does not have enough collateral");
    });
  });
});
