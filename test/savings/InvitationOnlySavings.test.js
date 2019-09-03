const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const MoneyMarket = artifacts.require("MoneyMarket.sol");
const InvitationManager = artifacts.require("mock/InvitationManagerMock.sol");
const SavingsV2 = artifacts.require("savings/InvitationOnlySavings.sol");
const ERC20 = artifacts.require("mock/ERC20Mock.sol");
const ERC20Invalid = artifacts.require("mock/ERC20MockInvalid.sol");
const ERC20Fails = artifacts.require("mock/ERC20MockFails.sol");
const Calculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const ZeroCalculator = artifacts.require("calculator/ZeroSavingsInterestCalculator.sol");

const { ZERO_ADDRESS, MAX_UINT256 } = constants;

const ZERO = new BN(0);
const MULTIPLIER = new BN(10).pow(new BN(18));
const MAX_AMOUNT = MULTIPLIER.mul(new BN("50000000"));
const AMOUNT1 = MULTIPLIER.mul(new BN(100));
const AMOUNT2 = MULTIPLIER.mul(new BN(150));
const AMOUNT3 = MULTIPLIER.mul(new BN(200));
const AMOUNTS = [AMOUNT1, AMOUNT2, AMOUNT3];
const WITHDRAW_AMOUNT = MULTIPLIER.mul(new BN(50));
const DAYS_10 = time.duration.days(10);
const DAYS_30 = time.duration.days(30);
const DAYS_365 = time.duration.days(365);
const DAYS = [DAYS_10, DAYS_30, DAYS_365];
const MINIMUM_SAVINGS_AMOUNT = MULTIPLIER.mul(new BN(100));

contract("InvitationOnlySavings", function([
  admin,
  notAdmin,
  user1,
  user2,
  user3,
  not_allowed_user,
  insufficient_user,
  not_registered_user
]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.calculator = await Calculator.new();
    this.zeroCalculator = await ZeroCalculator.new();
    this.invitationManager = await InvitationManager.new();

    this.users = [user1, user2, user3, not_allowed_user, not_registered_user];

    for (const [i, u] of this.users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: admin });
    }

    await this.invitationManager.setRedeemed(user1, true);
    await this.invitationManager.setRedeemed(user2, true);
    await this.invitationManager.setRedeemed(user3, true);
    await this.invitationManager.setRedeemed(not_allowed_user, true);
    await this.invitationManager.setRedeemed(insufficient_user, true);
  });

  beforeEach(async function() {
    this.base = await MoneyMarket.new(admin, this.dai.address, this.zeroCalculator.address);
    this.savings = await SavingsV2.new();
    await this.base.setLoan(this.savings.address);
    this.market = await SavingsV2.at(this.base.address);
    await this.market.initialize(
      this.zeroCalculator.address,
      this.calculator.address,
      this.invitationManager.address,
      MINIMUM_SAVINGS_AMOUNT
    );

    for (const [i, u] of this.users.slice(0, 3).entries()) {
      await this.dai.approve(this.market.address, MAX_UINT256, { from: u });
    }
  });

  it("should get right information", async function() {
    const decimals = await this.market.DECIMALS();
    expect(decimals).to.be.bignumber.equal(new BN(18));

    const multiplier = await this.market.MULTIPLIER();
    expect(multiplier).to.be.bignumber.equal(MULTIPLIER);

    expect(await this.market.savingsCalculator()).to.be.equal(this.zeroCalculator.address);
    expect(await this.market.invitationOnlySavingsCalculator()).to.be.equal(this.calculator.address);
    expect(await this.market.invitationManager()).to.be.equal(this.invitationManager.address);
    expect(await this.market.minimumSavingsAmount()).to.be.bignumber.equal(MINIMUM_SAVINGS_AMOUNT);
  });

  it("should get same asset", async function() {
    const asset = await this.market.asset();
    expect(asset).to.be.equal(this.dai.address);
  });

  it("should get same interest rate", async function() {
    let expectedRate = await this.calculator.getInterestRate(
      await this.market.totalFunds(),
      0,
      await this.market.MULTIPLIER()
    );
    let expectedRate2 = await this.market.getCurrentInvitationOnlySavingsInterestRate();

    expect(expectedRate).to.be.bignumber.equal(expectedRate2);

    let expectedRate3 = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, AMOUNT3);
    let expectedRate4 = await this.market.getExpectedInvitationOnlySavingsInterestRate(AMOUNT3);

    expect(expectedRate3).to.be.bignumber.equal(expectedRate4);

    let expectedAPR = (await this.calculator.getExpectedBalance(MULTIPLIER, expectedRate, 365 * 86400)).sub(MULTIPLIER);
    let expectedAPR2 = await this.market.getCurrentInvitationOnlySavingsAPR();

    expect(expectedAPR).to.be.bignumber.equal(expectedAPR2);

    let expectedAPR3 = (await this.calculator.getExpectedBalance(MULTIPLIER, expectedRate3, 365 * 86400)).sub(
      MULTIPLIER
    );

    let expectedAPR4 = await this.market.getExpectedInvitationOnlySavingsAPR(AMOUNT3);

    expect(expectedAPR3).to.be.bignumber.equal(expectedAPR4);
  });

  context("new functions", function() {
    it("should not initialize twice", async function() {
      await expectRevert(
        this.market.initialize(
          this.zeroCalculator.address,
          this.calculator.address,
          this.invitationManager.address,
          MINIMUM_SAVINGS_AMOUNT
        ),
        "version already initialized"
      );
    });

    it("should set and get SavingsInterestCalculator", async function() {
      const newCalculator = await Calculator.new();

      let { logs } = await this.market.setInvitationOnlySavingsCalculator(newCalculator.address, {
        from: admin
      });

      expectEvent.inLogs(logs, "InvitationOnlySavingsCalculatorChanged", {
        previousCalculator: this.calculator.address,
        newCalculator: newCalculator.address
      });

      expect(await this.market.invitationOnlySavingsCalculator()).to.be.equal(newCalculator.address);
    });

    it("should not set SavingsInterestCalculator when address is ZERO_ADDRESS", async function() {
      await expectRevert(
        this.market.setInvitationOnlySavingsCalculator(ZERO_ADDRESS, { from: admin }),
        "new calculator is zero address"
      );
    });

    it("should not set SavingsInterestCalculator when not called from owner", async function() {
      const calculator = await Calculator.new();

      await expectRevert(
        this.market.setInvitationOnlySavingsCalculator(calculator.address, { from: notAdmin }),
        "not called from owner"
      );
    });

    it("should set and get InvitationManager", async function() {
      const newManager = await InvitationManager.new();

      let { logs } = await this.market.setInvitationManager(newManager.address, {
        from: admin
      });

      expectEvent.inLogs(logs, "InvitationManagerChanged", {
        previousManager: this.invitationManager.address,
        newManager: newManager.address
      });

      expect(await this.market.invitationManager()).to.be.equal(newManager.address);
    });

    it("should not set InvitationManager when address is ZERO_ADDRESS", async function() {
      await expectRevert(
        this.market.setInvitationManager(ZERO_ADDRESS, { from: admin }),
        "new invitation repository is zero address"
      );
    });

    it("should not set InvitationManager when not called from owner", async function() {
      const repository = await InvitationManager.new();

      await expectRevert(
        this.market.setInvitationManager(repository.address, { from: notAdmin }),
        "not called from owner"
      );
    });

    it("should set and get Minimum Savings Amount", async function() {
      const newAmount = MINIMUM_SAVINGS_AMOUNT.mul(new BN(2));
      let { logs } = await this.market.setMinimumSavingsAmount(newAmount, {
        from: admin
      });

      expectEvent.inLogs(logs, "MinimumSavingsAmountChanged", {
        from: MINIMUM_SAVINGS_AMOUNT,
        to: newAmount
      });

      expect(await this.market.minimumSavingsAmount()).to.be.bignumber.equal(newAmount);
    });

    it("should not set Minimum Savings Amount when not called from owner", async function() {
      const newAmount = MINIMUM_SAVINGS_AMOUNT.mul(new BN(2));

      await expectRevert(this.market.setMinimumSavingsAmount(newAmount, { from: notAdmin }), "not called from owner");
    });
  });

  context("saving", function() {
    context("deposit", function() {
      it("should deposit ", async function() {
        let expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, AMOUNT1);

        let { logs } = await this.market.invitationOnlyDeposit(AMOUNT1, { from: user1 });

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(0),
          owner: user1,
          balance: AMOUNT1,
          rate: expectedRate
        });

        let record = await this.market.getSavingsRecord(new BN(0));
        expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT1);
        expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

        expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, AMOUNT2);
        ({ logs } = await this.market.invitationOnlyDeposit(AMOUNT2, { from: user1 }));

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(1),
          owner: user1,
          balance: AMOUNT2,
          rate: expectedRate
        });

        record = await this.market.getSavingsRecord(new BN(1));
        expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT2);
        expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

        expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, AMOUNT3);
        ({ logs } = await this.market.invitationOnlyDeposit(AMOUNT3, { from: user1 }));

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(2),
          owner: user1,
          balance: AMOUNT3,
          rate: expectedRate
        });

        record = await this.market.getSavingsRecord(new BN(2));
        expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT3);
        expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

        const records = await this.market.getSavingsRecords(user1);

        expect(records).to.be.lengthOf(3);

        records.forEach((record, i) => {
          expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNTS[i]);
        });

        const recordIds = await this.market.getSavingsRecordIds(user1);
        const eachRecords = await Promise.all(
          recordIds.map(async recordId => await this.market.getSavingsRecord(recordId))
        );

        for (let i = 0; i < records.length; i++) {
          expect(records[i].id).to.be.equal(eachRecords[i].id);
          expect(records[i].owner).to.be.equal(eachRecords[i].owner);
          expect(records[i].interestRate).to.be.equal(eachRecords[i].interestRate);
          expect(records[i].balance).to.be.equal(eachRecords[i].balance);
          expect(records[i].principal).to.be.equal(eachRecords[i].principal);
          expect(records[i].initialTimestamp).to.be.equal(eachRecords[i].initialTimestamp);
        }
      });

      it("should not deposit when amount is ZERO", async function() {
        await expectRevert(this.market.invitationOnlyDeposit(ZERO, { from: user1 }), "invalid amount");
      });

      it("should not deposit when user doesn't registered invitation code", async function() {
        await expectRevert(
          this.market.invitationOnlyDeposit(AMOUNT1, { from: not_registered_user }),
          "user does not registered invitation code"
        );
      });

      it("should not deposit when amount is not exceeds minimum amount", async function() {
        await expectRevert(
          this.market.invitationOnlyDeposit(MINIMUM_SAVINGS_AMOUNT.sub(new BN(1)), { from: user1 }),
          "invalid amount"
        );
      });

      it("should not deposit when user does not have enough fund", async function() {
        await expectRevert(
          this.market.invitationOnlyDeposit(AMOUNT1, { from: insufficient_user }),
          "insufficient fund"
        );
      });

      it("should not deposit when user does not approved bank", async function() {
        await expectRevert(this.market.invitationOnlyDeposit(AMOUNT1, { from: not_allowed_user }), "allowance not met");
      });

      it("should not deposit when ERC20.transferFrom() fails", async function() {
        const erc20fails = await ERC20Fails.new("ERC20 Fails", "Fail", 18);
        let market = await MoneyMarket.new(admin, erc20fails.address, this.calculator.address);
        await market.setLoan(this.savings.address);
        market = await SavingsV2.at(market.address);
        market.initialize(
          this.zeroCalculator.address,
          this.calculator.address,
          this.invitationManager.address,
          MINIMUM_SAVINGS_AMOUNT
        );

        await erc20fails.mint(user1, MAX_AMOUNT, { from: admin });
        await erc20fails.approve(market.address, MAX_UINT256, { from: user1 });
        await erc20fails.setShouldFail(true);

        await expectRevert(market.invitationOnlyDeposit(AMOUNT1, { from: user1 }), "transferFrom failed");

        await erc20fails.setShouldRevert(true);
        await expectRevert(market.invitationOnlyDeposit(AMOUNT1, { from: user1 }), "Token reverts");
      });

      it("should not deposit when ERC20 is Invalid", async function() {
        const erc20invalid = await ERC20Invalid.new("ERC20 Invalid", "Invalid", 18);
        let market = await MoneyMarket.new(admin, erc20invalid.address, this.calculator.address);
        await market.setLoan(this.savings.address);
        market = await SavingsV2.at(market.address);
        market.initialize(
          this.zeroCalculator.address,
          this.calculator.address,
          this.invitationManager.address,
          MINIMUM_SAVINGS_AMOUNT
        );

        await erc20invalid.mint(user1, MAX_AMOUNT, { from: admin });
        await erc20invalid.approve(market.address, MAX_UINT256, { from: user1 });

        // @dev just revert because IERC20 specifies transferFrom returns bool, but
        // ERC20Invalid's transferFrom returns nothing
        await expectRevert.unspecified(market.invitationOnlyDeposit(AMOUNT1, { from: user1 }));
      });
    });

    context("with deposit", function() {
      it("should not get savings record when savingsId is invalid", async function() {
        await expectRevert(this.market.getSavingsRecord(25), "invalid recordId");
        await expectRevert(this.market.getRawSavingsRecord(25), "invalid recordId");
      });

      context("should withdraw", function() {
        beforeEach(async function() {
          await this.market.invitationOnlyDeposit(AMOUNT1, { from: user1 });
          await this.market.invitationOnlyDeposit(AMOUNT2, { from: user1 });
          await this.market.invitationOnlyDeposit(AMOUNT3, { from: user1 });
        });

        it("raw savings balance is not updated before withdrawal", async function() {
          await time.increaseTo((await time.latest()).add(DAYS_10));

          const records = await this.market.getSavingsRecords(user1);
          expect(records).to.be.lengthOf(3);
          records.forEach((record, i) => {
            expect(new BN(record.balance)).to.be.not.bignumber.equal(AMOUNTS[i]);
          });

          const rawRecords = await this.market.getRawSavingsRecords(user1);
          expect(rawRecords).to.be.lengthOf(3);
          rawRecords.forEach((record, i) => {
            expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNTS[i]);
          });
        });

        it("should withdraw", async function() {
          const records = await this.market.getSavingsRecords(user1);

          for (const [i, r] of records.entries()) {
            await time.increaseTo((await time.latest()).add(DAYS[i]));
            const record = await this.market.getSavingsRecord(r.id);
            const rawRecord = await this.market.getRawSavingsRecord(r.id);
            const diff = new BN(record.balance).sub(new BN(rawRecord.balance));
            const expectedRemaining = new BN(record.balance).sub(WITHDRAW_AMOUNT);

            // give market enough funds
            await this.dai.mint(this.market.address, diff, { from: admin });

            const { logs } = await this.market.withdraw(record.id, WITHDRAW_AMOUNT, {
              from: user1
            });

            expectEvent.inLogs(logs, "SavingsWithdrawn", {
              recordId: record.id,
              owner: user1,
              amount: WITHDRAW_AMOUNT,
              remainingBalance: expectedRemaining
            });

            const changedRecord = await this.market.getSavingsRecord(record.id);

            expect(new BN(changedRecord.balance)).to.be.bignumber.equal(expectedRemaining);
          }
        });

        it("should withdraw full funds", async function() {
          const records = await this.market.getSavingsRecords(user1);

          for (const [i, r] of records.entries()) {
            await time.increaseTo((await time.latest()).add(DAYS[i]));
            const record = await this.market.getSavingsRecord(r.id);
            const rawRecord = await this.market.getRawSavingsRecord(r.id);
            const diff = new BN(record.balance).sub(new BN(rawRecord.balance));

            // give market enough funds
            await this.dai.mint(this.market.address, diff, { from: admin });
            const { logs } = await this.market.withdraw(record.id, record.balance, {
              from: user1
            });

            expectEvent.inLogs(logs, "SavingsWithdrawn", {
              recordId: record.id,
              owner: user1,
              amount: record.balance,
              remainingBalance: ZERO
            });

            const changedRecord = await this.market.getSavingsRecord(record.id);

            expect(new BN(changedRecord.balance)).to.be.bignumber.equal(ZERO);
          }
        });
      });
    });

    context("should not withdraw", function() {
      beforeEach(async function() {
        await this.market.invitationOnlyDeposit(AMOUNT1, { from: user1 });
        await this.market.invitationOnlyDeposit(AMOUNT2, { from: user2 });
        await this.market.invitationOnlyDeposit(AMOUNT3, { from: user3 });
      });

      it("when savingsId is invalid", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));

        await this.dai.mint(this.market.address, diff, { from: admin });
        await expectRevert(this.market.withdraw(5, WITHDRAW_AMOUNT, { from: user1 }), "invalid recordId");
      });

      it("when savings is not owned by user", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));

        await this.dai.mint(this.market.address, diff, { from: admin });
        await expectRevert(this.market.withdraw(0, WITHDRAW_AMOUNT, { from: user3 }), "invalid owner");
      });

      it("when withdraw more than balance", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));
        const INVALID_AMOUNT = new BN(record.balance).add(new BN(1));

        await this.dai.mint(this.market.address, diff, { from: admin });
        await expectRevert(this.market.withdraw(0, INVALID_AMOUNT, { from: user1 }), "insufficient balance");
      });

      it("when total fund is not enough", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        let record = await this.market.getSavingsRecord(0);
        await this.market.withdraw(0, record.balance, { from: user1 });

        record = await this.market.getSavingsRecord(1);
        await this.market.withdraw(1, record.balance, { from: user2 });

        record = await this.market.getSavingsRecord(2);
        await expectRevert(this.market.withdraw(2, record.balance, { from: user3 }), "insufficient fund");
      });

      it("when ERC20.transfer fails", async function() {
        const erc20fails = await ERC20Fails.new("ERC20 Fails", "Fail", 18);
        let market = await MoneyMarket.new(admin, erc20fails.address, this.calculator.address);
        await market.setLoan(this.savings.address);
        market = await SavingsV2.at(market.address);
        market.initialize(
          this.zeroCalculator.address,
          this.calculator.address,
          this.invitationManager.address,
          MINIMUM_SAVINGS_AMOUNT
        );

        await erc20fails.mint(user1, MAX_AMOUNT, { from: admin });
        await erc20fails.approve(market.address, MAX_UINT256, { from: user1 });
        await erc20fails.setShouldFail(false);

        await market.invitationOnlyDeposit(AMOUNT1, { from: user1 });
        await erc20fails.setShouldFail(true);

        await expectRevert(market.withdraw(0, AMOUNT1, { from: user1 }), "transfer failed");

        await erc20fails.setShouldRevert(true);
        await expectRevert(market.withdraw(0, AMOUNT1, { from: user1 }), "Token reverts");
      });
    });
  });
});
