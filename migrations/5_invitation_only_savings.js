require("dotenv").config();
const InvitationOnlySavings = artifacts.require("savings/InvitationOnlySavings.sol");

module.exports = async function(deployer, network, [admin]) {
  if (!["extdev", "plasma"].includes(network)) {
    return;
  }

  await deployer.deploy(InvitationOnlySavings);

  console.log("Don't forget to `setLoan` and `initialize`!!!");
};
