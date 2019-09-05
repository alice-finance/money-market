```uml
class IInterestCalculator {
+ getInterestRate
+ getExpectedBalance
}

class SavingsInterestCalculatorV1 {
}

class ZeroSavingsInterestCalculator {
}

class ISavings {
+ depositWithData()
+ withdrawWithData()
+ getSavingsRecordIdsWithData()
+ getSavingsRecordsWithData()
+ getSavingsRecordWithData()
+ getRawSavingsRecordsWithData()
+ getRawSavingsRecordWithData()
+ getCurrentSavingsInterestRateWithData()
+ getCurrentSavingsAPRWithData()
+ getExpectedSavingsInterestRateWithData()
+ getExpectedSavingsAPRWithData()
+ savingsCalculatorWithData()
+ setSavingsCalculatorWithData(IInterestCalculator calculator)
}

class Ownable {
+ owner() 
+ isOwner() 
+ transferOwnership(address newOwner) 
}

class Asset {
+ asset()
}

class Upgradable {
+ loan() 
+ setLoan(address newLoanAddress) 
+ savingsCalculator() 
+ setSavingsCalculator(IInterestCalculator calculator)
}

class Fund {
+ totalFunds() 
+ totalBorrows() 
}

class Savings {
+ savingsCalculatorWithData()
+ setSavingsCalculatorWithData(IInterestCalculator calculator)
}

class MinimumAmountRequiredSavings {
+ minimumSavingsAmount()
+ setMinimumSavingsAmount(uint256 amount)
}

class IInvitationManager {
+ inviter()
+ invitationSlots()
+ isRedeemed()
+ redemptions()
+ redemptionCount()
+ totalRedeemed()
+ redeem()
}

class InvitationOnlySavingsBase{
}

Ownable <|-- Asset
Asset <|-- Upgradable

Upgradable *- IInterestCalculator : have 1 >

Upgradable <|-- Fund
ISavings <|-- Savings
Fund <|-- Savings

Savings <|-- MinimumAmountRequiredSavings
Savings *- IInterestCalculator : have n >

MinimumAmountRequiredSavings <|-- InvitationOnlySavingsBase
IInvitationManager <|-- InvitationOnlySavingsBase

IInterestCalculator <|--  SavingsInterestCalculatorV1
IInterestCalculator <|--  ZeroSavingsInterestCalculator
```
