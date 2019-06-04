const MoneyMarket = artifacts.require("MoneyMarket.sol");
const SavingsInterestCalculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ERC20Mock = artifacts.require("mock/ERC20Mock.sol");

module.exports = async function(deployer, network) {
  if (["development", "localdev", "coverage"].includes(network)) {
    let dai = await ERC20Mock.deployed();
    if (dai) {
      daiAddress = dai.address;
    } else {
      await deployer.deploy(ERC20Mock, "DAI Stable Coin", "DAI", 18);
      const dai = await ERC20Mock.deployed();
      daiAddress = dai.address;
    }
  } else if (network == "extdev") {
    daiAddress = "0xCeCd059CDe0138Cb681fF9bf9445a0a2CC9e98cb";
  } else {
    throw Error("Network Error");
  }

  const calculator = await SavingsInterestCalculator.deployed();
  await deployer.deploy(MoneyMarket, daiAddress, calculator.address);
};
