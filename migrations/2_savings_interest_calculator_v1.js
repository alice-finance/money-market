const SavingsInterestCalculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");

module.exports = async function(deployer) {
  await deployer.deploy(SavingsInterestCalculator);
};
