# transactions Specification

## Purpose

Records income, expenses, and transfers quickly so wallet balances and every report reflect what the user actually spent and received.

## Requirements

### Requirement: Record an expense

Users SHALL be able to record an expense with a whole-rupiah amount greater than zero, an active wallet, an expense category, a date, and an optional note. Saving SHALL decrease the wallet balance immediately.

#### Scenario: Save an expense
- **WHEN** the user saves a Rp 35.000 expense from wallet "BCA" in category "Makan" dated today
- **THEN** a transaction appears in history and the BCA balance decreases by Rp 35.000

#### Scenario: Invalid amount
- **WHEN** the amount is zero, negative, fractional, or empty
- **THEN** the app blocks saving and identifies the amount as invalid

### Requirement: Record income

Users SHALL be able to record income with a whole-rupiah amount greater than zero, an active wallet, an income category, a date, and an optional note. Saving SHALL increase the wallet balance immediately.

#### Scenario: Save income
- **WHEN** the user saves a Rp 5.000.000 income to wallet "Mandiri" in category "Gaji"
- **THEN** a transaction appears in history and the Mandiri balance increases by Rp 5.000.000

### Requirement: Amount limits

A single transaction amount SHALL be at most Rp 999.999.999.999, and the app SHALL reject amounts above that limit with a clear message.

#### Scenario: Excessive amount
- **WHEN** the user enters Rp 1.000.000.000.000
- **THEN** the app blocks saving and states the maximum allowed amount

### Requirement: Entry defaults

The expense and income forms SHALL open with the amount field focused, today's date, and the last-used wallet and category for that kind preselected. With no history, the first active wallet and first category of that kind SHALL be preselected.

#### Scenario: Repeat expense
- **WHEN** the user adds an expense after previously using wallet "BCA" and category "Makan"
- **THEN** the new form already has BCA and Makan selected

#### Scenario: First entry
- **WHEN** the user adds the first expense
- **THEN** the first active wallet and first expense category are preselected

#### Scenario: Archived last-used wallet
- **WHEN** the last-used wallet has been archived
- **THEN** the form selects the first active wallet instead

### Requirement: Amount input

Amount fields SHALL accept digits only, add Indonesian grouping separators while typing, use the numeric keyboard, and reject letters and decimal separators.

#### Scenario: Grouping while typing
- **WHEN** the user types 35000 into the amount field
- **THEN** the field displays 35.000

#### Scenario: Pasted value
- **WHEN** the user pastes "35.000" into the amount field
- **THEN** the field keeps the value 35.000 instead of multiplying it

#### Scenario: Invalid characters
- **WHEN** the user types or pastes letters into the amount field
- **THEN** the letters are ignored

### Requirement: Category management

The app SHALL seed default income and expense categories and SHALL let users create, rename, and archive categories of either kind. Archived categories SHALL remain on existing transactions.

#### Scenario: Archive a used category
- **WHEN** the user archives category "Makan" that already has transactions
- **THEN** "Makan" disappears from new-entry pickers while existing transactions still show the name

#### Scenario: Create a category
- **WHEN** the user creates an expense category named "Kopi"
- **THEN** "Kopi" becomes selectable for new expenses

### Requirement: Edit a transaction

Editing a transaction SHALL update its amount, wallet, category, date, or note and SHALL re-derive affected wallet balances and reports atomically.

#### Scenario: Move an expense to another wallet
- **WHEN** the user changes a Rp 20.000 expense from wallet A to wallet B
- **THEN** wallet A's balance increases by Rp 20.000, wallet B's balance decreases by Rp 20.000, and only one transaction exists

#### Scenario: Change the amount
- **WHEN** the user edits a Rp 20.000 expense to Rp 30.000
- **THEN** the wallet balance decreases by the additional Rp 10.000

### Requirement: Delete a transaction

Deleting a transaction SHALL require confirmation, SHALL reverse its balance effect, and SHALL remove it from history and reports.

#### Scenario: Delete an expense
- **WHEN** the user confirms deletion of a Rp 40.000 expense
- **THEN** the transaction disappears and the wallet balance increases by Rp 40.000

#### Scenario: Cancel deletion
- **WHEN** the user dismisses the confirmation dialog
- **THEN** the transaction and balances remain unchanged

### Requirement: Transfer between wallets

Users SHALL be able to transfer money between two different active wallets. A transfer SHALL move the amount atomically and SHALL NOT count as income or expense in reports.

#### Scenario: Successful transfer
- **WHEN** the user transfers Rp 100.000 from "BCA" to "GoPay"
- **THEN** BCA decreases by Rp 100.000, GoPay increases by Rp 100.000, and monthly income and expense totals are unchanged

#### Scenario: Same wallet
- **WHEN** the user selects the same wallet as source and destination
- **THEN** the app blocks the transfer and explains that the wallets must differ

#### Scenario: Insufficient balance
- **WHEN** the source wallet has less than the transfer amount
- **THEN** the app warns about the resulting negative balance and still saves only after confirmation

### Requirement: Transfer fee

A transfer MAY include an optional fee. The fee SHALL be recorded as an expense on the source wallet and SHALL appear in expense reports and category breakdowns.

#### Scenario: Transfer with fee
- **WHEN** the user transfers Rp 100.000 with a Rp 6.500 fee
- **THEN** the destination gains Rp 100.000, the source loses Rp 106.500, and Rp 6.500 appears as an expense

### Requirement: Transaction dates

A new transaction date SHALL default to today and MUST NOT be in the future. Dates SHALL be selected with an Indonesian-locale date picker.

#### Scenario: Future date
- **WHEN** the user selects a date after today
- **THEN** the app blocks saving and explains that future transactions are not allowed

### Requirement: Single submission

Repeated taps on the save action SHALL create exactly one transaction.

#### Scenario: Double tap save
- **WHEN** the user taps save twice rapidly on the same expense form
- **THEN** only one transaction is stored and only one balance change occurs

### Requirement: Transaction history

Users SHALL browse transactions in reverse chronological order grouped by date, showing wallet, category, note, and signed amount, with a clear empty state when none exist.

#### Scenario: Grouped history
- **WHEN** the user opens history with entries on two different dates
- **THEN** entries appear under date headings with the newest date first

#### Scenario: Empty history
- **WHEN** no transactions exist
- **THEN** the app shows one sentence explaining the empty state and an action to add the first transaction
