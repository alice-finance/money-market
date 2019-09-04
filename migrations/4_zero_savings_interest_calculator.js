require("dotenv").config();
const ZeroSavingsInterestCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  await deployer.deploy(ZeroSavingsInterestCalculator);
};
