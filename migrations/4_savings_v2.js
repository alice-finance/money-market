require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const SavingsV2 = artifacts.require("savings/InvitationOnlySavings.sol");
const InvitationCode = artifacts.require("marketing/IInvitationRepository.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  const market = await MoneyMarket.deployed();
  await deployer.deploy(InvitationCode, market.address, "25000000000000000000");
};
