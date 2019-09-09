require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const ZeroSavingsInterestCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");
const SavingsInterestCalculatorV1 = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const InvitationOnlySavings = artifacts.require("savings/InvitationOnlySavings.sol");

const MINIMUM_SAVINGS_AMOUNT = "25000000000000000000";
const AMOUNT_PER_INVITE = "25000000000000000000";

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  await deployer.deploy(InvitationOnlySavings);

  const base = await MoneyMarket.deployed();
  const savings = await InvitationOnlySavings.deployed();
  const zeroCalculator = await ZeroSavingsInterestCalculator.deployed();
  const calculator = await SavingsInterestCalculatorV1.deployed();

  if (network === "extdev") {
    await base.setLoan(savings.address);
    const market = await InvitationOnlySavings.at(base.address);

    await market.setSavingsCalculator(zeroCalculator.address);
    await market.setSavingsCalculatorWithData(calculator.address, []);
    await market.setMinimumSavingsAmount(MINIMUM_SAVINGS_AMOUNT);
    await market.setAmountOfSavingsPerInvite(AMOUNT_PER_INVITE);
  } else {
    console.log("Next steps:");
    console.log("- Don't forget to:");
    console.log(`  - setLoan("${savings.address}")`);
    console.log(`  - setSavingsCalculator("${zeroCalculator.address}")`);
    console.log(`  - setSavingsCalculatorWithData("${calculator.address}", [])`);
    console.log(`  - setMinimumSavingsAmount("${MINIMUM_SAVINGS_AMOUNT}")`);
    console.log(`  - setAmountOfSavingsPerInvite("${AMOUNT_PER_INVITE}")`);
  }
};
