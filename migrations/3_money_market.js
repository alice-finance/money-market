const MoneyMarket = artifacts.require("MoneyMarket.sol");
const SavingsInterestCalculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ERC20Mock = artifacts.require("mock/ERC20Mock.sol");

module.exports = async function(deployer, network, [admin]) {
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

  } else if (network == "extdev") {
    daiAddress = "0xCeCd059CDe0138Cb681fF9bf9445a0a2CC9e98cb";
    ownerAddress = "0x3F887AaFCed05ea8fC16390624Cb6B7f588Ccb2a";
  } else {
    throw Error("Network Error");
  }

  const calculator = await SavingsInterestCalculator.deployed();
  await deployer.deploy(MoneyMarket, ownerAddress, daiAddress, calculator.address);
};
