const { constants, BN, expectEvent, expectRevert, time } = require("openzeppelin-test-helpers");
const { expect } = require("chai");

const MoneyMarket = artifacts.require("MoneyMarket.sol");
const ERC20 = artifacts.require("mock/ERC20Mock.sol");
const Calculator = artifacts.require("calculator/SavingsInterestCalculatorV1.sol");
const TrustlessOwner = artifacts.require("ownership/TrustlessOwnerMock.sol");

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

contract("Savings", function([owner, user1, user2, user3, not_allowed_user, insufficient_user]) {
  before(async function() {
    this.dai = await ERC20.new("DAI Stable Token", "DAI", 18);
    this.calculator = await Calculator.new();
    this.owner = await TrustlessOwner.new();

    users = [user1, user2, user3, not_allowed_user];

    for (const [i, u] of users.entries()) {
      await this.dai.mint(u, MAX_AMOUNT, { from: owner });
    }
  });

  beforeEach(async function() {
    this.market = await MoneyMarket.new(this.dai.address, this.calculator.address);
    this.market.transferOwnership(this.owner.address, { from: owner });

    for (const [i, u] of users.slice(0, 3).entries()) {
      await this.dai.approve(this.market.address, MAX_UINT256, { from: u });
    }
  });

  context("saving", function() {
    context("deposit", function() {
      it("should deposit ", async function() {
        let expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, 0);

        let { logs } = await this.market.deposit(AMOUNT1, { from: user1 });

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(0),
          owner: user1,
          balance: AMOUNT1,
          rate: expectedRate
        });

        let record = await this.market.getSavingsRecord(new BN(0));
        expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT1);
        expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

        expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, 0);
        ({ logs } = await this.market.deposit(AMOUNT2, { from: user1 }));

        expectEvent.inLogs(logs, "SavingsDeposited", {
          recordId: new BN(1),
          owner: user1,
          balance: AMOUNT2,
          rate: expectedRate
        });

        record = await this.market.getSavingsRecord(new BN(1));
        expect(new BN(record.balance)).to.be.bignumber.equal(AMOUNT2);
        expect(new BN(record.interestRate)).to.be.bignumber.equal(expectedRate);

        expectedRate = await this.calculator.getInterestRate(await this.market.totalFunds(), 0, 0);
        ({ logs } = await this.market.deposit(AMOUNT3, { from: user1 }));

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
        await expectRevert(this.market.deposit(ZERO, { from: user1 }), "invalid amount");
      });

      it("should not deposit when user does not have enough fund", async function() {
        await expectRevert(this.market.deposit(AMOUNT1, { from: insufficient_user }), "insufficient fund");
      });

      it("should not deposit when user does not approved bank", async function() {
        await expectRevert(this.market.deposit(AMOUNT1, { from: not_allowed_user }), "allowance not met");
      });
    });

    context("with deposit", function() {
      it("should not get savings record when savingsId is invalid", async function () {
        await expectRevert(this.market.getSavingsRecord(25), "invalid recordId")
        await expectRevert(this.market.getRawSavingsRecord(25), "invalid recordId")
      });

      context("should withdraw", function() {
        beforeEach(async function() {
          await this.market.deposit(AMOUNT1, { from: user1 });
          await this.market.deposit(AMOUNT2, { from: user1 });
          await this.market.deposit(AMOUNT3, { from: user1 });
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
            await this.dai.mint(this.market.address, diff, { from: owner });

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
            await this.dai.mint(this.market.address, diff, { from: owner });
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
        await this.market.deposit(AMOUNT1, { from: user1 });
        await this.market.deposit(AMOUNT2, { from: user2 });
        await this.market.deposit(AMOUNT3, { from: user3 });
      });

      it("when savingsId is invalid", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));

        await this.dai.mint(this.market.address, diff, { from: owner });
        await expectRevert(this.market.withdraw(5, WITHDRAW_AMOUNT, { from: user1 }), "invalid recordId");
      });

      it("when savings is not owned by user", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));

        await this.dai.mint(this.market.address, diff, { from: owner });
        await expectRevert(this.market.withdraw(0, WITHDRAW_AMOUNT, { from: user3 }), "invalid owner");
      });

      it("when withdraw more than balance", async function() {
        await time.increaseTo((await time.latest()).add(DAYS_10));

        const record = await this.market.getSavingsRecord(0);
        const rawRecord = await this.market.getRawSavingsRecord(0);
        const diff = new BN(record.balance).sub(new BN(rawRecord.balance));
        const INVALID_AMOUNT = new BN(record.balance).add(new BN(1));

        await this.dai.mint(this.market.address, diff, { from: owner });
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
    });
  });
});
