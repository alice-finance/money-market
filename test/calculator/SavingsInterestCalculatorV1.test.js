const { constants, BN } = require("openzeppelin-test-helpers");
const { expect } = require("chai");
const { MAX_UINT256 } = constants;

const SavingsInterestCalculatorV1 = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");

function getExpectedBalance(principal, rate, terms) {
  return new BN(Array.from({ length: terms }).reduce(a => Math.floor(a * (1 + rate)), principal));
}

contract("SavingsInterestCalculatorV1", function([owner]) {
  beforeEach(async function() {
    this.calculator = await SavingsInterestCalculatorV1.new();
    this.MULTIPLIER = await this.calculator.MULTIPLIER();
  });

  it("should get interest rate", async function() {
    const INITIAL_EXPECTED_RATE = new BN("210874398376755");
    const HALF_EXPECTED_RATE = new BN("105437418902571");
    const MAX_SAVINGS = this.MULTIPLIER.mul(new BN("2000000"));
    const HALF_SAVINGS = this.MULTIPLIER.mul(new BN("1000000"));
    const OVER_SAVINGS = MAX_SAVINGS.add(this.MULTIPLIER.mul(new BN(100000)));
    const OVERFLOW_SAVINGS = MAX_UINT256;
    const FINAL_EXPECTED_RATE = new BN(0);

    let rate = await this.calculator.getInterestRate(0, 0, 0);

    expect(rate).to.be.bignumber.equal(INITIAL_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(HALF_SAVINGS, 0, 0);

    expect(rate).to.be.bignumber.equal(HALF_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(MAX_SAVINGS, 0, 0);

    expect(rate).to.be.bignumber.equal(FINAL_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(0, 0, MAX_SAVINGS);

    expect(rate).to.be.bignumber.equal(HALF_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(HALF_SAVINGS, 0, MAX_SAVINGS);

    expect(rate).to.be.bignumber.equal(FINAL_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(OVER_SAVINGS, 0, 0);

    expect(rate).to.be.bignumber.equal(FINAL_EXPECTED_RATE);

    rate = await this.calculator.getInterestRate(OVERFLOW_SAVINGS, 0, 0);

    expect(rate).to.be.bignumber.equal(FINAL_EXPECTED_RATE);
  });
});
