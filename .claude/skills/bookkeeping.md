# Bookkeeping Expert Skill

## Purpose
Expert knowledge in double-entry bookkeeping, income statement preparation, and bookkeeping software design principles. Use this skill to review financial code, validate accounting logic, and ensure proper bookkeeping practices.

## Core Accounting Principles

### The Accounting Equation (MUST ALWAYS BALANCE)
```
Assets = Liabilities + Equity
```
Every transaction must maintain this balance.

### Double-Entry Bookkeeping Rules
- Every transaction has at least 2 entries (debit and credit)
- Debits MUST equal credits in every transaction
- Transactions recorded in Journals → Summarized → Posted to General Ledger

### Account Behavior Reference

| Account Type | Increases with | Decreases with | Normal Balance |
|--------------|----------------|----------------|----------------|
| Assets | Debit | Credit | Debit |
| Liabilities | Credit | Debit | Credit |
| Equity | Credit | Debit | Credit |
| Revenue/Sales | Credit | Debit | Credit |
| Expenses | Debit | Credit | Debit |
| COGS | Debit | Credit | Debit |

### Permanent vs Temporary Accounts

**Permanent Accounts (Balance Sheet):**
- Assets, Liabilities, Equity
- Balances carry forward month-to-month
- NEVER reset to zero

**Temporary Accounts (Income Statement):**
- Revenue, Expenses, COGS
- Reset to zero at end of each accounting period
- Measure performance for a specific period

## Income Statement Structure

### The 7 Essential Lines (in order):

```
1. Revenue/Sales
   - Sales Discounts
   - Sales Returns & Allowances
   ─────────────────────────────
   = Net Sales

2. - Cost of Goods Sold (COGS)
   ─────────────────────────────
   = Gross Profit

3. - Operating Expenses
   ─────────────────────────────
   = Profit from Operations

4. + Other Income
   - Other Expenses
   ─────────────────────────────
   = Net Profit/Loss
```

### Critical Calculations

**Net Sales:**
```
Gross Sales - Sales Discounts - Sales Returns & Allowances = Net Sales
```

**Cost of Goods Sold:**
```
Opening Inventory
+ Purchases
- Purchase Discounts
- Ending Inventory
= Cost of Goods Sold
```

**Gross Profit** (calculated subtotal, NOT a General Ledger account):
```
Net Sales - Cost of Goods Sold = Gross Profit
```

### Presentation Standards
- Show **3 periods** (current + 2 prior) for trend analysis
- Use **multi-step format** (includes subtotals like Gross Profit and Profit from Operations)
- Can show **percentage of Net Sales** for each line item
- **Internal reports**: Show full expense detail
- **External reports**: Summarize expenses (don't reveal too much)

## Classification Rules

### Revenue vs Other Income
- **Revenue**: Money from primary business operations (selling products/services)
- **Other Income**: Non-operating income (interest, rent from subletting, asset sales)

### COGS vs Expenses
- **Cost of Goods Sold**: Direct costs to buy/make products that were sold
- **Operating Expenses**: Costs to run the business not tied to specific product sales (rent, salaries, advertising, utilities)

### Operating vs Non-Operating
- **Operating Expenses**: Normal business operations (salaries, rent, advertising)
- **Other Expenses**: Non-operating costs (interest on loans)

## Code Review Checklist

When reviewing bookkeeping code, verify:

### ✓ Data Integrity
- [ ] Every transaction has balanced debits and credits
- [ ] Account balances can't become invalid (e.g., negative Cash with debit balance)
- [ ] Audit trail maintained (reference to source journal/document)
- [ ] Transactions are immutable once posted
- [ ] Corrections use adjusting entries, not deletion

### ✓ Account Structure
- [ ] Chart of Accounts properly organized (Assets → Liabilities → Equity → Revenue → Expenses)
- [ ] Account types correctly assigned
- [ ] Temporary accounts close at period end
- [ ] Permanent accounts carry forward
- [ ] Normal balances match account types

### ✓ Income Statement Generation
- [ ] Net Sales calculated correctly (subtracts discounts and returns)
- [ ] COGS calculated correctly (Opening Inv + Purchases - Discounts - Ending Inv)
- [ ] Gross Profit shown as subtotal (Net Sales - COGS)
- [ ] Operating Expenses properly classified and grouped
- [ ] Profit from Operations shown (Gross Profit - Operating Expenses)
- [ ] Other Income/Expenses separated from operating results
- [ ] Net Profit calculated correctly

### ✓ Account Classification
- [ ] Revenue properly distinguished from Other Income
- [ ] COGS separated from Operating Expenses
- [ ] Operating Expenses separated from Other Expenses
- [ ] Assets vs Expenses (capitalize vs expense decision)

### ✓ Period Handling
- [ ] Accounting periods clearly defined
- [ ] Temporary accounts reset each period
- [ ] Permanent accounts maintain continuity
- [ ] Period-end closing process works correctly

## Common Anti-Patterns to Flag

### ❌ Unbalanced Transactions
```javascript
// BAD: Debits don't equal credits
transaction: {
  debit: { account: 'Cash', amount: 100 },
  credit: { account: 'Sales', amount: 95 }
}
```

### ✅ Properly Balanced
```javascript
// GOOD: Debits = Credits
transaction: {
  debits: [{ account: 'Cash', amount: 100 }],
  credits: [{ account: 'Sales', amount: 100 }]
}
```

### ❌ Mixing COGS with Operating Expenses
```javascript
// BAD: Purchases should be COGS, not lumped with expenses
expenses: [
  { name: 'Purchases', amount: 5000 },
  { name: 'Rent', amount: 800 }
]
```

### ✅ Proper Classification
```javascript
// GOOD: COGS separate from Operating Expenses
costOfGoodsSold: [
  { name: 'Purchases', amount: 5000 }
],
operatingExpenses: [
  { name: 'Rent', amount: 800 }
]
```

### ❌ Wrong Gross Profit Calculation
```javascript
// BAD: Gross Profit is NOT revenue minus all expenses
grossProfit = revenue - totalExpenses
```

### ✅ Correct Gross Profit
```javascript
// GOOD: Gross Profit = Net Sales - COGS only
grossProfit = netSales - costOfGoodsSold
```

### ❌ Revenue Carrying Forward Between Periods
```javascript
// BAD: January revenue still in account in February
// January: Sales = $10,000
// February starts: Sales = $10,000 (WRONG!)
```

### ✅ Revenue Resets Each Period
```javascript
// GOOD: Temporary accounts reset
// January: Sales = $10,000 → closes to Retained Earnings
// February starts: Sales = $0
```

## Design Patterns for Bookkeeping Apps

### Transaction Data Model
```javascript
Transaction {
  id: UUID
  date: Date
  description: String
  journalReference: String // Cash Receipts, Cash Disbursements, etc.
  entries: [
    {
      accountId: UUID,
      debitAmount: Decimal,
      creditAmount: Decimal
    }
  ]
  // Constraint: sum(debitAmount) === sum(creditAmount)
}
```

### Account Data Model
```javascript
Account {
  id: UUID
  code: String // e.g., "1000", "4000"
  name: String // e.g., "Cash", "Sales Revenue"
  type: Enum('Asset', 'Liability', 'Equity', 'Revenue', 'Expense', 'COGS')
  normalBalance: Enum('Debit', 'Credit') // derived from type
  isPermanent: Boolean // true for Balance Sheet accounts
  parentAccountId: UUID? // for sub-accounts
}
```

### Income Statement Generator Pattern
```javascript
function generateIncomeStatement(startDate, endDate) {
  // 1. Calculate Net Sales
  const sales = getAccountBalance('Revenue', startDate, endDate)
  const discounts = getAccountBalance('Sales Discounts', startDate, endDate)
  const returns = getAccountBalance('Sales Returns', startDate, endDate)
  const netSales = sales - discounts - returns

  // 2. Calculate COGS
  const cogs = calculateCOGS(startDate, endDate)

  // 3. Calculate Gross Profit (subtotal)
  const grossProfit = netSales - cogs

  // 4. Sum Operating Expenses
  const operatingExpenses = sumAccountsByType('Expense', startDate, endDate)

  // 5. Calculate Profit from Operations (subtotal)
  const profitFromOperations = grossProfit - operatingExpenses

  // 6. Add Other Income, subtract Other Expenses
  const otherIncome = getAccountBalance('Other Income', startDate, endDate)
  const otherExpenses = getAccountBalance('Other Expenses', startDate, endDate)

  // 7. Calculate Net Profit
  const netProfit = profitFromOperations + otherIncome - otherExpenses

  return {
    netSales,
    cogs,
    grossProfit,
    operatingExpenses: operatingExpenses.details,
    totalOperatingExpenses: operatingExpenses.total,
    profitFromOperations,
    otherIncome,
    otherExpenses,
    netProfit,
    percentages: calculatePercentages(netSales, ...)
  }
}
```

## Financial Analysis Capabilities

### Key Profitability Ratios

**Margin Analysis:**
```javascript
grossProfitMargin = (grossProfit / netSales) * 100
operatingMargin = (profitFromOperations / netSales) * 100
netProfitMargin = (netProfit / netSales) * 100
```

**Return Ratios:**
```javascript
returnOnSales = (profit / netSales) * 100
returnOnAssets = (profit / totalAssets) * 100
returnOnEquity = (profit / totalEquity) * 100
```

### Trend Analysis
- Compare current period to prior periods
- Calculate percentage change
- Flag significant variations (e.g., COGS % jumping from 32% to 35%)
- Monitor Gross Profit trends

### Red Flags to Identify
- Declining Gross Profit margin (COGS increasing faster than sales)
- Operating Expenses growing faster than revenue
- Unusual spikes in specific expense categories
- Revenue declining while expenses remain constant

## When to Apply This Skill

Automatically apply when encountering:
- Financial transaction recording code
- Database schemas for accounting data
- Income statement or financial report generation
- Account balance calculations
- Period-end closing logic
- Financial data validation
- Profit/loss calculations

## Common Business Scenarios

### Scenario: Recording a Sale on Credit
```javascript
// Customer buys $100 on account
{
  debits: [
    { account: 'Accounts Receivable', amount: 100 }
  ],
  credits: [
    { account: 'Sales Revenue', amount: 100 }
  ]
}
```

### Scenario: Paying Rent
```javascript
// Pay $800 rent
{
  debits: [
    { account: 'Rent Expense', amount: 800 }
  ],
  credits: [
    { account: 'Cash', amount: 800 }
  ]
}
```

### Scenario: Purchasing Inventory
```javascript
// Buy inventory for resale: $5,000 on credit
{
  debits: [
    { account: 'Purchases', amount: 5000 } // COGS category
  ],
  credits: [
    { account: 'Accounts Payable', amount: 5000 }
  ]
}
```

### Scenario: Owner Invests Cash
```javascript
// Owner puts $10,000 into business
{
  debits: [
    { account: 'Cash', amount: 10000 }
  ],
  credits: [
    { account: 'Owner Capital', amount: 10000 }
  ]
}
```

## Key Terminology

- **Debit**: Left side of account; increases Assets/Expenses, decreases Liabilities/Equity/Revenue
- **Credit**: Right side of account; decreases Assets/Expenses, increases Liabilities/Equity/Revenue
- **Journal**: Original book of entry where transactions first recorded
- **General Ledger**: Master collection of all accounts showing balances
- **Trial Balance**: List of all accounts with debit/credit balances to verify books balance
- **Posting**: Transferring journal entries to General Ledger accounts
- **Adjusting Entry**: Correction or adjustment to previously recorded transaction
- **Closing Entries**: End-of-period entries that reset temporary accounts to zero

## References
- Double-entry bookkeeping (Bookkeeping for Dummies, Ch 2)
- Chart of Accounts structure (Ch 3)
- General Ledger system (Ch 4)
- Income Statement preparation (Ch 19)
