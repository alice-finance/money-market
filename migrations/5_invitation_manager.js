require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const ZeroSavingsInterestCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");
const InvitationOnlySavings = artifacts.require("savings/InvitationOnlySavings.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  await deployer.deploy(InvitationOnlySavings, "25000000000000000000");

  console.log("Next steps:");
  console.log("- Don't forget to `setLoan` and `initialize`!!!");
  console.log("- Also set savings calculator to deployed `ZeroSavingsInterestCalculator`");
  console.log("  using `setSavingsCalculator`");
};
