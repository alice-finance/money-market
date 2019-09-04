require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const SavingsInterestCalculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ERC20Mock = artifacts.require("mock/ERC20Mock.sol");

module.exports = async function(deployer, network, [admin]) {
  let daiAddress;
  let ownerAddress;
  if (["development", "localdev", "coverage"].includes(network)) {
    let dai;
    try {
      dai = await ERC20Mock.deployed();
    } catch (e) {
      await deployer.deploy(ERC20Mock, "DAI Stable Coin", "DAI", 18);
      dai = await ERC20Mock.deployed();
    }

    if (dai) {
      daiAddress = dai.address;
    } else {
      throw Error("Cannot find dai");
    }

    ownerAddress = admin;
  } else if (["extdev", "plasma"].includes(network)) {
    daiAddress = process.env.DAI_ADDRESS;
    ownerAddress = process.env.OWNER_ADDRESS;
  } else {
    return;
    // throw Error("Network Error");
  }

  const calculator = await SavingsInterestCalculator.deployed();
  await deployer.deploy(MoneyMarket, ownerAddress, daiAddress, calculator.address);
};
