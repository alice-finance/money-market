require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const InvitationManager = artifacts.require("InvitationManager");
const ZeroSavingsInterestCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");
const InvitationOnlySavings = artifacts.require("savings/InvitationOnlySavings.sol.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  await deployer.deploy(InvitationOnlySavings);

  console.log("Don't forget to `setLoan` and `initialize`!!!");
};
