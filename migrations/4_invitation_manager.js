require("dotenv").config();
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const InvitationManager = artifacts.require("marketing/InvitationManager.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  const market = await MoneyMarket.deployed();
  await deployer.deploy(InvitationManager, market.address, "25000000000000000000");
};
