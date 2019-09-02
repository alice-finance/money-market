const { BN, expectEvent, expectRevert } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const InvitationRepository = artifacts.require("marketing/InvitationRepository.sol");
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

contract("InvitationRepository", function([admin, newAdmin, notAdmin, inviter, invitee1, invitee2, invitee3]) {
  beforeEach(async function() {
    this.market = await MarketMock.new();
    this.repository = await InvitationRepository.new(this.market.address, AMOUNT_PER_INVITE, { from: admin });
  });

  it("should change amount per invite", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));

    expect(await this.repository.amountPerInvite()).to.be.bignumber.equal(AMOUNT_PER_INVITE);

    const { logs } = await this.repository.setAmountPerInvite(newAmount, { from: admin });

    expectEvent.inLogs(logs, "AmountPerInviteChanged", {
      from: AMOUNT_PER_INVITE,
      to: newAmount
    });

    expect(await this.repository.amountPerInvite()).to.be.bignumber.equal(newAmount);
  });

  it("should not change amount per invite when caller is not owner", async function() {
    const newAmount = AMOUNT_PER_INVITE.div(new BN(5));
    await expectRevert(
      this.repository.setAmountPerInvite(newAmount, { from: notAdmin }),
      "InvitationRepository: not called from owner"
    );
  });

  it("should not change amount per invite when amount is ZERO", async function() {
    await expectRevert(
      this.repository.setAmountPerInvite(ZERO, { from: admin }),
      "InvitationRepository: amount is ZERO"
    );
  });

  it("should transfer ownership", async function() {
    expect(await this.repository.owner()).to.be.equal(admin);
    const { logs } = await this.repository.transferOwnership(newAdmin, { from: admin });
    expectEvent.inLogs(logs, "OwnershipTransferred", {
      previousOwner: admin,
      newOwner: newAdmin
    });
    expect(await this.repository.owner()).to.be.equal(newAdmin);
  });

  it("should transfer ownership when caller is not owner", async function() {
    await expectRevert(
      this.repository.transferOwnership(newAdmin, { from: notAdmin }),
      "InvitationRepository: not called from owner"
    );
  });

  it("should redeem code", async function() {
    await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

    expect(await this.repository.inviteeCount(inviter)).to.be.bignumber.equal(new BN(0));
    expect(await this.repository.maxInviteeCount(inviter)).to.be.bignumber.equal(new BN(3));
    expect(await this.repository.totalRegistered()).to.be.bignumber.equal(new BN(0));

    const code = generateCode(inviter, 1);
    const signature = await generateSignature(generateHash(code), inviter);

    const { logs } = await this.repository.redeem(code, signature, { from: invitee1 });

    expectEvent.inLogs(logs, "InvitationCodeUsed", {
      inviter,
      code,
      account: invitee1
    });

    expect(await this.repository.isRegistered(invitee1)).to.be.true;
    expect(await this.repository.inviter(invitee1)).to.be.equal(inviter);
    expect((await this.repository.invitees(inviter))[0]).to.be.equal(invitee1);
    expect(await this.repository.inviteeCount(inviter)).to.be.bignumber.equal(new BN(1));
    expect(await this.repository.maxInviteeCount(inviter)).to.be.bignumber.equal(new BN(3));
    expect(await this.repository.totalRegistered()).to.be.bignumber.equal(new BN(1));
  });

  context("should not redeem when", function() {
    it("user already redeemed code", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.repository.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await expectRevert(
        this.repository.redeem(code2, signature2, { from: invitee1 }),
        "InvitationRepository: already registered user"
      );
    });

    it("signature does not match", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await expectRevert(
        this.repository.redeem(code, signature2, { from: invitee1 }),
        "InvitationRepository: wrong code"
      );
    });

    it("inviter doesn't deposited savings", async function() {
      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await expectRevert(
        this.repository.redeem(code, signature, { from: invitee1 }),
        "InvitationRepository: max count reached"
      );
    });

    it("inviter does not deposited enough amount", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(2)), 0);
      expect(await this.repository.maxInviteeCount(inviter)).to.be.bignumber.equal(new BN(2));

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.repository.redeem(code, signature, { from: invitee1 });

      const code2 = generateCode(inviter, 2);
      const signature2 = await generateSignature(generateHash(code2), inviter);

      await this.repository.redeem(code2, signature2, { from: invitee2 });

      const code3 = generateCode(inviter, 3);
      const signature3 = await generateSignature(generateHash(code3), inviter);

      await expectRevert(
        this.repository.redeem(code3, signature3, { from: invitee3 }),
        "InvitationRepository: max count reached"
      );

      expect(await this.repository.totalRegistered()).to.be.bignumber.equal(new BN(2));
    });

    it("code already used", async function() {
      await this.market.setSavingsRecord(1, inviter, AMOUNT_PER_INVITE.mul(new BN(3)), 0);

      const code = generateCode(inviter, 1);
      const signature = await generateSignature(generateHash(code), inviter);

      await this.repository.redeem(code, signature, { from: invitee1 });

      await expectRevert(
        this.repository.redeem(code, signature, { from: invitee2 }),
        "InvitationRepository: code already used"
      );
    });
  });
});
