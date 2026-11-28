# Spec Delta

## Purpose

Tracks utang and piutang separately from wallet balances and commits a movement to the main ledger only when the user chooses.

## ADDED Requirements

### Requirement: Create a debt or receivable

Users SHALL record an entry as utang (the user owes) or piutang (the user is owed), with a counterparty, whole-rupiah principal, start date, optional due date, and optional note.

#### Scenario: Record utang
- **WHEN** the user saves an utang of Rp 500.000 owed to "Budi"
- **THEN** the entry appears in the debt list with remaining Rp 500.000 and status open

#### Scenario: Missing counterparty
- **WHEN** the user submits an entry without a counterparty
- **THEN** the app blocks saving and identifies the field as required

### Requirement: Ledger isolation

Creating, editing, paying, or deleting a debt entry SHALL NOT change any wallet balance unless the user commits that specific entry.

#### Scenario: Debt without commit
- **WHEN** the user records an utang without choosing to commit it
- **THEN** wallet balances, income, and expenses remain unchanged

#### Scenario: Reports exclude uncommitted debts
- **WHEN** the user opens analytics after recording uncommitted debts
- **THEN** the debt amounts do not appear in income or expense totals

### Requirement: Partial payments

Users SHALL record payments against a debt entry, each with an amount, date, and optional note. A payment SHALL NOT exceed the remaining amount, and remaining SHALL equal principal minus recorded payments.

#### Scenario: Partial payment
- **WHEN** the user pays Rp 200.000 of a Rp 500.000 utang
- **THEN** remaining becomes Rp 300.000 and the entry stays open

#### Scenario: Overpayment
- **WHEN** the user enters a payment greater than the remaining amount
- **THEN** the app blocks saving and shows the maximum allowed payment

#### Scenario: Settle in full
- **WHEN** payments equal the principal
- **THEN** remaining becomes Rp 0 and the entry is marked settled

### Requirement: Debt status

A debt entry SHALL show open or settled status and SHALL be marked overdue when it has a due date in the past and remaining above zero.

#### Scenario: Overdue utang
- **WHEN** an open utang passes its due date
- **THEN** it is visibly marked overdue in the debt list

### Requirement: Commit a ledger entry

When creating a debt entry or recording a payment, the user MAY commit that movement to the main ledger by choosing an active wallet and a category. No ledger entry SHALL be committed automatically.

#### Scenario: Commit prompt
- **WHEN** the user saves an utang with a wallet and category selected for commit
- **THEN** the movement becomes a real transaction and the wallet balance changes accordingly

#### Scenario: Decline commit
- **WHEN** the user leaves the commit option off
- **THEN** no transaction is created and the entry stays ledger-only

### Requirement: Commit direction

The committed transaction direction SHALL follow the cash movement: utang principal becomes income, utang repayment becomes expense, piutang principal becomes expense, and piutang repayment becomes income.

#### Scenario: Borrowing money
- **WHEN** the user commits the principal of an utang
- **THEN** an income transaction is created in the chosen wallet

#### Scenario: Receiving a repayment
- **WHEN** the user commits a payment received on a piutang
- **THEN** an income transaction is created in the chosen wallet

### Requirement: Commit wording

Before saving, the commit control SHALL name the wallet and the transaction direction it will create, using income or expense wording.

#### Scenario: Utang principal
- **WHEN** the user selects wallet "BCA" to commit a borrowed utang
- **THEN** the control reads "Pemasukan ke BCA"

#### Scenario: Utang repayment
- **WHEN** the user selects wallet "BCA" to commit an utang repayment
- **THEN** the control reads "Pengeluaran dari BCA"

### Requirement: Single commit per entry

Each ledger entry SHALL link to at most one transaction and SHALL NOT be committed again while that link exists. If the linked transaction is deleted, the link SHALL be cleared and the entry MAY be committed again.

#### Scenario: Prevent double commit
- **WHEN** the user tries to commit an entry that is already linked to a transaction
- **THEN** the app blocks the action and identifies the linked transaction

#### Scenario: Linked transaction deleted
- **WHEN** the user deletes the transaction created by a commit
- **THEN** the debt entry returns to uncommitted and can be committed again

### Requirement: Debt summary

The debt screen SHALL show total outstanding utang and total outstanding piutang separately, counting only entries with remaining above zero.

#### Scenario: Mixed debts
- **WHEN** the user has Rp 500.000 outstanding utang and Rp 150.000 outstanding piutang
- **THEN** the screen shows those two totals separately instead of one net figure

### Requirement: Delete a debt entry

Deleting a debt entry SHALL require confirmation and SHALL remove its ledger history. Any transactions already committed from that entry SHALL remain in the main ledger.

#### Scenario: Delete committed debt
- **WHEN** the user confirms deletion of a debt entry whose principal was committed
- **THEN** the debt and its payments disappear while the committed wallet transaction remains
