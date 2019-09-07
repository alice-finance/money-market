const { BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const Savings = artifacts.require("mock/savings/InvitationOnlySavingsMock.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");
const MoneyMarket = artifacts.require("MoneyMarket.sol");
const Calculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ZeroCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");

const ZERO = new BN(0);
const MULTIPLIER = new BN(10).pow(new BN(18));
const MAX_AMOUNT = MULTIPLIER.mul(new BN("50000000"));
const MINIMUM_SAVINGS_AMOUNT = MULTIPLIER.mul(new BN(100));
const AMOUNT_PER_INVITE = MULTIPLIER.mul(new BN(25));

const generateCode = (address, index) => {
  return address.toLowerCase() + ("000000000000000000000000" + index).slice(-24);
};

const generateHash = code => {
  return web3.utils.soliditySha3({ type: "bytes32", value: code });
};

const generateSignature = async (hash, address) => {
  return await web3.eth.sign(hash, address);
};

contract("InvitationOnlySavings.sol.invitation", function([admin, inviter1, inviter2, invitee1, invitee2, invitee3]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.calculator = await Calculator.new();
    this.zeroCalculator = await ZeroCalculator.new();

    this.users = [inviter1, inviter2, invitee1, invitee2, invitee3];

    for (const [i, u] of this.users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: admin });
    }
  });

  beforeEach(async function() {
    this.base = await MoneyMarket.new(admin, this.dai.address, this.zeroCalculator.address);
    await this.base.setSavingsCalculator(this.zeroCalculator.address);
    this.savings = await Savings.new();
    await this.base.setLoan(this.savings.address);
    this.market = await Savings.at(this.base.address);
    await this.market.initialize(this.calculator.address, MINIMUM_SAVINGS_AMOUNT);
    await this.market.setSavingsCalculator(this.zeroCalculator.address);

    for (const [i, u] of this.users.entries()) {
      await this.dai.approve(this.market.address, MAX_UINT256, { from: u });
    }
  });

  it("should change amount per invite", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));

    expect(await this.market.amountOfSavingsPerInvite()).to.be.bignumber.equal(AMOUNT_PER_INVITE);

    const { logs } = await this.market.setAmountOfSavingsPerInvite(newAmount, { from: admin });

    expectEvent.inLogs(logs, "AmountOfSavingsPerInviteChanged", {
      from: AMOUNT_PER_INVITE,
      to: newAmount
    });

    expect(await this.market.amountOfSavingsPerInvite()).to.be.bignumber.equal(newAmount);
  });

  it("should not change amount per invite when caller is not owner", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));
    await expectRevert(
      this.market.setAmountOfSavingsPerInvite(newAmount, { from: notAdmin }),
      "InvitationManager: not called from owner"
    );
  });

  it("should not change amount per invite when amount is ZERO", async function() {
    await expectRevert(
      this.market.setAmountOfSavingsPerInvite(ZERO, { from: admin }),
      "InvitationManager: amount is ZERO"
    );
  });

  it("should transfer ownership", async function() {
    expect(await this.market.owner()).to.be.equal(admin);
    const { logs } = await this.market.transferOwnership(newAdmin, { from: admin });
    expectEvent.inLogs(logs, "OwnershipTransferred", {
      previousOwner: admin,
      newOwner: newAdmin
    });
    expect(await this.market.owner()).to.be.equal(newAdmin);
  });

  it("should transfer ownership when caller is not owner", async function() {
    await expectRevert(
      this.market.transferOwnership(newAdmin, { from: notAdmin }),
      "InvitationManager: not called from owner"
    );
  });

  it("should redeem code", async function() {
    await this.market.setSavingsRecord(1, inviter1, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

    expect(await this.market.redeemerCount(inviter1)).to.be.bignumber.equal(new BN(0));
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(3));
    expect(await this.market.totalRedeemed()).to.be.bignumber.equal(new BN(0));

    const code = generateCode(inviter1, 1);
    const signature = await generateSignature(generateHash(code), inviter1);

    const { logs } = await this.market.redeem(code, signature, { from: invitee1 });

    expectEvent.inLogs(logs, "InvitationCodeUsed", {
      inviter1,
      code,
      account: invitee1
    });

    expect(await this.market.isRedeemed(invitee1)).to.be.true;
    expect(await this.market.inviter1(invitee1)).to.be.equal(inviter1);
    expect((await this.market.redeemers(inviter1))[0]).to.be.equal(invitee1);
    expect(await this.market.redeemerCount(inviter1)).to.be.bignumber.equal(new BN(1));
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(3));
    expect(await this.market.totalRedeemed()).to.be.bignumber.equal(new BN(1));
  });

  context("should not redeem when", function() {
    it("user already redeemed code", async function() {
      await this.market.setSavingsRecord(1, inviter1, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter1, 1);
      const signature = await generateSignature(generateHash(code), inviter1);

      await this.market.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter1, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter1);

      await expectRevert(
        this.market.redeem(code2, signature2, { from: invitee1 }),
        "InvitationManager: already redeemed user"
      );
    });

    it("signature does not match", async function() {
      await this.market.setSavingsRecord(1, inviter1, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter1, 1);
      const code2 = generateCode(inviter1, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter1);

      await expectRevert(this.market.redeem(code, signature2, { from: invitee1 }), "InvitationManager: wrong code");
    });

    it("inviter1 doesn't deposited savings", async function() {
      const code = generateCode(inviter1, 1);
      const signature = await generateSignature(generateHash(code), inviter1);

      await expectRevert(
        this.market.redeem(code, signature, { from: invitee1 }),
        "InvitationManager: max count reached"
      );
    });

    it("inviter1 does not deposited enough amount", async function() {
      await this.market.setSavingsRecord(1, inviter1, AMOUNT_PER_INVITE.mul(new BN(2)), 0);
      expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(2));

      const code = generateCode(inviter1, 1);
      const signature = await generateSignature(generateHash(code), inviter1);

      await this.market.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter1, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter1);

      await this.market.redeem(code2, signature2, { from: invitee2 });

      const code3 = generateCode(inviter1, 3);
      const signature3 = await generateSignature(generateHash(code3), inviter1);

      await expectRevert(
        this.market.redeem(code3, signature3, { from: invitee3 }),
        "InvitationManager: max count reached"
      );

      expect(await this.market.totalRedeemed()).to.be.bignumber.equal(new BN(2));
    });

    it("code already used", async function() {
      await this.market.setSavingsRecord(1, inviter1, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter1, 1);
      const signature = await generateSignature(generateHash(code), inviter1);

      await this.market.redeem(code, signature, { from: invitee1 });

      await expectRevert(
        this.market.redeem(code, signature, { from: invitee2 }),
        "InvitationManager: code already used"
      );
    });
  });
});
