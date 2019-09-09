const { BN, constants, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const Savings = artifacts.require("savings/InvitationOnlySavings.sol");
const ERC20 = artifacts.require("mock/token/ERC20Mock.sol");
const MoneyMarket = artifacts.require("mock/MoneyMarket.sol");
const Calculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ZeroCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");

const { MAX_UINT256 } = constants;
const ZERO = new BN(0);
const ZERO_BYTES = [];
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

contract("InvitationOnlySavings", function([admin, notAdmin, inviter1, inviter2, inviter3, invitee1, invitee2]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.calculator = await Calculator.new();
    this.zeroCalculator = await ZeroCalculator.new();

    this.users = [inviter1, inviter2, invitee1, invitee2];

    for (const [i, u] of this.users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: admin });
    }
  });

  beforeEach(async function() {
    this.base = await MoneyMarket.new(admin, this.dai.address, this.calculator.address);

    for (const [i, u] of this.users.slice(0, 4).entries()) {
      await this.dai.approve(this.base.address, MAX_UINT256, { from: u });
    }

    this.savings = await Savings.new();
    await this.base.setLoan(this.savings.address);
    this.market = await Savings.at(this.base.address);
    await this.market.setSavingsCalculator(this.zeroCalculator.address);
    await this.market.setSavingsCalculatorWithData(this.calculator.address, ZERO_BYTES);
    await this.market.setMinimumSavingsAmount(MINIMUM_SAVINGS_AMOUNT);
    await this.market.setAmountOfSavingsPerInvite(AMOUNT_PER_INVITE);

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
      "Ownable: not called from the owner"
    );
  });

  it("should not change amount per invite when amount is ZERO", async function() {
    await expectRevert(
      this.market.setAmountOfSavingsPerInvite(ZERO, { from: admin }),
      "InvitationManager: amount is ZERO"
    );
  });

  it("should get correct invitationSlots", async function() {
    await this.base.setSavingsCalculator(this.calculator.address);
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(ZERO);
    await this.base.deposit(AMOUNT_PER_INVITE.sub(new BN(1)), { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(ZERO);
    await this.base.deposit(new BN(1), { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(1));
    await this.base.deposit(AMOUNT_PER_INVITE, { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(2));
    await this.base.deposit(AMOUNT_PER_INVITE.div(new BN(2)), { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(2));
    await this.base.deposit(AMOUNT_PER_INVITE.div(new BN(2)), { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(3));
    await this.base.withdraw(4, AMOUNT_PER_INVITE.div(new BN(2)), { from: inviter1 });
    expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(2));
  });

  context("with previous deposit", async function() {
    beforeEach(async function() {
      await this.base.setSavingsCalculator(this.calculator.address);
      await this.base.deposit(AMOUNT_PER_INVITE.mul(new BN(3)), { from: inviter1 });
      await this.base.deposit(AMOUNT_PER_INVITE.div(new BN(2)), { from: inviter2 });
    });

    context("redeem", function() {
      it("should redeem code", async function() {
        expect(await this.market.redeemerCount(inviter1)).to.be.bignumber.equal(new BN(0));
        expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(3));
        expect(await this.market.totalRedeemed()).to.be.bignumber.equal(new BN(0));

        const code = generateCode(inviter1, 1);
        const signature = await generateSignature(generateHash(code), inviter1);
        const data = code + signature.slice(2);

        const { logs } = await this.market.redeem(data, { from: invitee1 });

        expectEvent.inLogs(logs, "InvitationCodeUsed", {
          inviter: inviter1,
          code,
          account: invitee1
        });

        expect(await this.market.isRedeemed(invitee1)).to.be.true;
        expect(await this.market.inviter(invitee1)).to.be.equal(inviter1);
        expect((await this.market.redeemers(inviter1))[0]).to.be.equal(invitee1);
        expect(await this.market.redeemerCount(inviter1)).to.be.bignumber.equal(new BN(1));
        expect(await this.market.invitationSlots(inviter1)).to.be.bignumber.equal(new BN(3));
        expect(await this.market.totalRedeemed()).to.be.bignumber.equal(new BN(1));
      });

      context("should not redeem when", function() {
        it("user already redeemed code", async function() {
          const code = generateCode(inviter1, 1);
          const signature = await generateSignature(generateHash(code), inviter1);
          const data = code + signature.slice(2);

          await this.market.redeem(data, { from: invitee1 });

          const code2 = generateCode(inviter1, 2);
          const signature2 = await generateSignature(generateHash(code2), inviter1);
          const data2 = code2 + signature2.slice(2);

          await expectRevert(this.market.redeem(data2, { from: invitee1 }), "InvitationManager: already redeemed user");
        });

        it("signature does not match", async function() {
          const code = generateCode(inviter1, 1);
          const code2 = generateCode(inviter1, 2);
          const signature2 = await generateSignature(generateHash(code2), inviter1);
          const data = code + signature2.slice(2);

          await expectRevert(this.market.redeem(data, { from: invitee1 }), "InvitationManager: wrong code");
        });

        it("inviter does not deposited enough amount", async function() {
          const code = generateCode(inviter2, 1);
          const signature = await generateSignature(generateHash(code), inviter2);
          const data = code + signature.slice(2);

          await expectRevert(this.market.redeem(data, { from: invitee1 }), "InvitationManager: max count reached");
        });

        it("inviter doesn't deposited savings", async function() {
          const code = generateCode(inviter3, 1);
          const signature = await generateSignature(generateHash(code), inviter3);
          const data = code + signature.slice(2);

          await expectRevert(this.market.redeem(data, { from: invitee1 }), "InvitationManager: max count reached");
        });

        it("code already used", async function() {
          const code = generateCode(inviter1, 1);
          const signature = await generateSignature(generateHash(code), inviter1);
          const data = code + signature.slice(2);

          await this.market.redeem(data, { from: invitee1 });

          await expectRevert(this.market.redeem(data, { from: invitee2 }), "InvitationManager: code already used");
        });
      });
    });
    context("depositWithData", function() {
      it("should deposit with code data", async function() {
        const code = generateCode(inviter1, 1);
        const signature = await generateSignature(generateHash(code), inviter1);
        const data = "0x01" + code.slice(2) + signature.slice(2);

        const { logs } = await this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data, { from: invitee1 });

        expectEvent.inLogs(logs, "InvitationCodeUsed", {
          inviter: inviter1,
          code,
          account: invitee1
        });

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(2),
          owner: invitee1,
          balance: MINIMUM_SAVINGS_AMOUNT
        });
      });

      it("should deposit with any data after redeemed", async function() {
        const code1 = generateCode(inviter1, 1);
        const signature1 = await generateSignature(generateHash(code1), inviter1);
        const data = "0x01" + code1.slice(2) + signature1.slice(2);

        await this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data, { from: invitee1 });

        await this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, ZERO_BYTES, { from: invitee1 });

        const code2 = generateCode(inviter1, 2);
        const signature2 = await generateSignature(generateHash(code2), inviter1);
        const data2 = code2 + signature2.slice(2);

        await this.market.redeem(data2, { from: invitee2 });

        await this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, ZERO_BYTES, { from: invitee2 });
      });

      it("should fail with invalid code", async function() {
        const code1 = generateCode(inviter1, 1);
        const signature1 = await generateSignature(generateHash(code1), inviter1);
        const data1 = "0x00" + code1.slice(2) + signature1.slice(2);
        await expectRevert(
          this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data1, { from: invitee1 }),
          "InvitationOnlySavings: not redeemed user"
        );

        const data2 = "0x01" + "00";

        await expectRevert(
          this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data2, { from: invitee1 }),
          "InvitationManager: invalid data"
        );

        const data3 = "0x01" + "0000000000000000000000000000000000000000" + "000000000000000000000000" + "00";

        await expectRevert(
          this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data3, { from: invitee1 }),
          "InvitationManager: invalid inviter"
        );

        const code4 = generateCode(inviter1, 0);
        const data4 = "0x01" + code4.slice(2) + "0000000000";

        await expectRevert(
          this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data4, { from: invitee1 }),
          "InvitationManager: invalid nonce"
        );

        const code5 = generateCode(inviter1, 1);
        const data5 = "0x01" + code4.slice(2);

        await expectRevert(
          this.market.depositWithData(MINIMUM_SAVINGS_AMOUNT, data5, { from: invitee1 }),
          "InvitationManager: invalid nonce"
        );
      });
    });
  });
});
