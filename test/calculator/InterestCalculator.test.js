const { expectRevert, BN } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const BaseInterestCalculator = artifacts.require("contracts/calculator/BaseInterestCalculator.sol");

async function getCalculatorBalance(principal, rate, terms) {
  const convertedTerms = terms * 86400;
  const convertedRate = this.MULTIPLIER.mul(new BN(rate * 100000)).div(new BN(100000));

  return await this.calculator.getExpectedBalance(principal, convertedRate, convertedTerms);
}

function getExpectedBalance(principal, rate, terms) {
  return new BN(Array.from({ length: terms }).reduce(a => Math.floor(a * (1 + rate)), principal));
}

contract("BaseInterestCalculator", function([owner]) {
  beforeEach(async function() {
    this.calculator = await BaseInterestCalculator.new();
    this.MULTIPLIER = await this.calculator.MULTIPLIER();
  });

  it("should get current balance", async function() {
    const principal = 100;
    const rate = 0.1;
    const terms = 10;

    const getBalance = getCalculatorBalance.bind(this);

    let result = await getBalance(principal, rate, terms);
    const expected = getExpectedBalance(principal, rate, terms);

    expect(result).to.be.bignumber.equal(expected);

    result = await getBalance(0, rate, terms);

    expect(result).to.be.bignumber.equal(new BN(0));

    result = await getBalance(principal, rate, 0);

    expect(result).to.be.bignumber.equal(new BN(principal));
  });

  it("should fail to get current balance when rate is ZERO", async function() {
    const getBalance = getCalculatorBalance.bind(this);

    await expectRevert(getBalance(100, 0, 10), "invalid rate");
  });

  it("should fail to get interest rate on BaseInterestCalculator", async function() {
    const totalSavings = 10000;
    const totalBorrows = 20000;
    const amount = 500;

    await expectRevert(this.calculator.getInterestRate(totalSavings, totalBorrows, amount), "not implemented");
  });
});
