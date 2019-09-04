const { BN, expectEvent, expectRevert } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const InvitationManager = artifacts.require("marketing/InvitationManager.sol.old");
const MarketMock = artifacts.require("mock/MarketMock.sol");

const ZERO = new BN(0);
const MULTIPLIER = new BN(10).pow(new BN(18));
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

contract("InvitationManager", function([admin, newAdmin, notAdmin, inviter, invitee1, invitee2, invitee3]) {
  beforeEach(async function() {
    this.market = await MarketMock.new();
    this.invitationManager = await InvitationManager.new(this.market.address, AMOUNT_PER_INVITE, { from: admin });
  });

  it("should change amount per invite", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));

    expect(await this.invitationManager.amountOfSavingsPerInvite()).to.be.bignumber.equal(AMOUNT_PER_INVITE);

    const { logs } = await this.invitationManager.setAmountOfSavingsPerInvite(newAmount, { from: admin });

    expectEvent.inLogs(logs, "AmountOfSavingsPerInviteChanged", {
      from: AMOUNT_PER_INVITE,
      to: newAmount
    });

    expect(await this.invitationManager.amountOfSavingsPerInvite()).to.be.bignumber.equal(newAmount);
  });

  it("should not change amount per invite when caller is not owner", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));
    await expectRevert(
      this.invitationManager.setAmountOfSavingsPerInvite(newAmount, { from: notAdmin }),
      "InvitationManager: not called from owner"
    );
  });

  it("should not change amount per invite when amount is ZERO", async function() {
    await expectRevert(
      this.invitationManager.setAmountOfSavingsPerInvite(ZERO, { from: admin }),
      "InvitationManager: amount is ZERO"
    );
  });

  it("should transfer ownership", async function() {
    expect(await this.invitationManager.owner()).to.be.equal(admin);
    const { logs } = await this.invitationManager.transferOwnership(newAdmin, { from: admin });
    expectEvent.inLogs(logs, "OwnershipTransferred", {
      previousOwner: admin,
      newOwner: newAdmin
    });
    expect(await this.invitationManager.owner()).to.be.equal(newAdmin);
  });

  it("should transfer ownership when caller is not owner", async function() {
    await expectRevert(
      this.invitationManager.transferOwnership(newAdmin, { from: notAdmin }),
      "InvitationManager: not called from owner"
    );
  });

  it("should redeem code", async function() {
    await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

    expect(await this.invitationManager.redemptionCount(inviter)).to.be.bignumber.equal(new BN(0));
    expect(await this.invitationManager.invitationSlots(inviter)).to.be.bignumber.equal(new BN(3));
    expect(await this.invitationManager.totalRedeemed()).to.be.bignumber.equal(new BN(0));

    const code = generateCode(inviter, 1);
    const signature = await generateSignature(generateHash(code), inviter);

    const { logs } = await this.invitationManager.redeem(code, signature, { from: invitee1 });

    expectEvent.inLogs(logs, "InvitationCodeUsed", {
      inviter,
      code,
      account: invitee1
    });

    expect(await this.invitationManager.isRedeemed(invitee1)).to.be.true;
    expect(await this.invitationManager.inviter(invitee1)).to.be.equal(inviter);
    expect((await this.invitationManager.redemptions(inviter))[0]).to.be.equal(invitee1);
    expect(await this.invitationManager.redemptionCount(inviter)).to.be.bignumber.equal(new BN(1));
    expect(await this.invitationManager.invitationSlots(inviter)).to.be.bignumber.equal(new BN(3));
    expect(await this.invitationManager.totalRedeemed()).to.be.bignumber.equal(new BN(1));
  });

  context("should not redeem when", function() {
    it("user already redeemed code", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.invitationManager.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await expectRevert(
        this.invitationManager.redeem(code2, signature2, { from: invitee1 }),
        "InvitationManager: already redeemed user"
      );
    });

    it("signature does not match", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await expectRevert(
        this.invitationManager.redeem(code, signature2, { from: invitee1 }),
        "InvitationManager: wrong code"
      );
    });

    it("inviter doesn't deposited savings", async function() {
      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await expectRevert(
        this.invitationManager.redeem(code, signature, { from: invitee1 }),
        "InvitationManager: max count reached"
      );
    });

    it("inviter does not deposited enough amount", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(2)), 0);
      expect(await this.invitationManager.invitationSlots(inviter)).to.be.bignumber.equal(new BN(2));

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.invitationManager.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await this.invitationManager.redeem(code2, signature2, { from: invitee2 });

      const code3 = generateCode(inviter, 3);
      const signature3 = await generateSignature(generateHash(code3), inviter);

      await expectRevert(
        this.invitationManager.redeem(code3, signature3, { from: invitee3 }),
        "InvitationManager: max count reached"
      );

      expect(await this.invitationManager.totalRedeemed()).to.be.bignumber.equal(new BN(2));
    });

    it("code already used", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.invitationManager.redeem(code, signature, { from: invitee1 });

      await expectRevert(
        this.invitationManager.redeem(code, signature, { from: invitee2 }),
        "InvitationManager: code already used"
      );
    });
  });
});
