const MoneyMarket = artifacts.require('contracts/MoneyMarket.sol')
const SavingsInterestCalculator = artifacts.require('contracts/calculator/SavingsInterestCalculatorV1.sol')
const ERC20Mock = artifacts.require('contracts/mock/ERC20Mock.sol')

const { readFileSync, writeFileSync } = require('fs')
const path = require('path')

module.exports = async function(deployer, network) {
  if (network == 'development' || network == 'localdev' || network == 'coverage') {
    await deployer.deploy(ERC20Mock, 'DAI Stable Coin', 'DAI', 18)
    const dai = await ERC20Mock.deployed()
    daiAddress = dai.address
  } else if (network == 'extdev') {
    daiAddress = '0xCeCd059CDe0138Cb681fF9bf9445a0a2CC9e98cb'
  } else {
    throw Error('Network Error')
  }

  await deployer.deploy(SavingsInterestCalculator)
  const calculator = await SavingsInterestCalculator.deployed()
  await deployer.deploy(MoneyMarket, daiAddress, calculator.address)
  const market = await MoneyMarket.deployed()

  let parent = path.normalize(path.join(__dirname, '..'))
  let jsonFilename = path.join(parent, `address_${network}.json`)

  let data = readFileSync(jsonFilename, { encoding: 'utf8', flag: 'w+' })
  var address = data ? JSON.parse(data) : {}
  address = {
    market: market.address,
    saving_interest_calculator: calculator.address,
    dai: daiAddress,
    ...address
  }

  writeFileSync(jsonFilename, JSON.stringify(address), { flag: 'w+' })
}
