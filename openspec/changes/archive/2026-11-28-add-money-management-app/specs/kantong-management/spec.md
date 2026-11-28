# Spec Delta

## Purpose

Models cash, bank, and e-wallet balances and keeps each wallet balance accurate.

## ADDED Requirements

### Requirement: First-run wallet setup

When no wallet exists, the app SHALL guide the user to create the first wallet before recording any money. The first-run flow SHALL require no account or network.

#### Scenario: First launch
- **WHEN** the user opens the app with no wallets stored
- **THEN** the app presents the first-wallet form and cannot save money movements until a wallet exists

#### Scenario: First wallet created
- **WHEN** the user saves the first wallet
- **THEN** the app returns to Beranda with that wallet visible and ready for entries

### Requirement: Create a kantong

Users SHALL be able to create a kantong with a required name, a type, an opening balance in whole rupiah, and a chosen icon and color. Names SHALL be unique ignoring case and surrounding whitespace. The create form SHALL start with the name field focused and the type set to Tunai.

#### Scenario: Create a wallet
- **WHEN** the user submits a name, type, opening balance, icon, and color
- **THEN** the wallet appears in the wallet list with its opening balance

#### Scenario: New wallet defaults
- **WHEN** the user opens the create-wallet form
- **THEN** the name field is focused, the keyboard is open, and the type is Tunai

#### Scenario: Duplicate name
- **WHEN** the user submits a name that matches an existing wallet ignoring case
- **THEN** the app rejects the submission and keeps the form open

#### Scenario: Empty name
- **WHEN** the user submits a wallet without a name
- **THEN** the app blocks saving and identifies the name field as required

### Requirement: Wallet types

The app SHALL support the wallet types Tunai, Bank, E-Wallet, and Lainnya, each with a distinct default Material Symbols icon and color suggestion.

#### Scenario: Wallet type displayed
- **WHEN** a wallet of type Bank appears in any list
- **THEN** it displays its type label and bank icon

### Requirement: Edit a kantong

Users SHALL be able to rename a wallet and change its type, icon, color, and opening balance. Changing the opening balance SHALL adjust the current balance by the same amount without altering recorded transactions.

#### Scenario: Change opening balance
- **WHEN** the user increases a wallet's opening balance from Rp 100.000 to Rp 250.000
- **THEN** the current balance increases by Rp 150.000 and all transactions remain unchanged

#### Scenario: Rename wallet
- **WHEN** the user renames a wallet
- **THEN** the new name appears in history and reports that reference that wallet

### Requirement: Balance derivation

A wallet's current balance SHALL equal its opening balance plus income and incoming transfers, minus expenses, outgoing transfers, and transfer fees recorded against it.

#### Scenario: Multiple movements
- **WHEN** a wallet starts at Rp 100.000, receives Rp 50.000 income, and pays a Rp 25.000 expense
- **THEN** its current balance is Rp 125.000

### Requirement: Negative balance warning

A wallet balance MAY become negative. The app SHALL save the movement, show a warning treatment for that wallet, and include the negative amount in totals.

#### Scenario: Expense exceeds balance
- **WHEN** the user records a Rp 200.000 expense from a wallet holding Rp 50.000
- **THEN** the expense is saved and the wallet shows -Rp 150.000 with a warning treatment

### Requirement: Archive a kantong

Users SHALL be able to archive a wallet. Archived wallets SHALL be hidden from new-entry pickers but SHALL remain in history, reports, and wallet filters.

#### Scenario: Archive with history
- **WHEN** the user archives a wallet that has transactions
- **THEN** the wallet disappears from entry pickers while its transactions and reports remain intact

#### Scenario: Archived wallet filter
- **WHEN** the user opens analytics and selects an archived wallet
- **THEN** the report includes that wallet's historical transactions

### Requirement: Keep one active wallet

The app SHALL prevent archiving the last active wallet so that new entries always have a destination.

#### Scenario: Archive last wallet
- **WHEN** the user attempts to archive the only active wallet
- **THEN** the app blocks the action and explains that at least one wallet must stay active

### Requirement: Delete a kantong

A wallet with no transactions SHALL be deletable after confirmation. A wallet with any transaction SHALL only be archivable, never deletable.

#### Scenario: Delete empty wallet
- **WHEN** the user confirms deletion of a wallet with no transactions
- **THEN** the wallet is removed permanently

#### Scenario: Delete wallet with history
- **WHEN** the user attempts to delete a wallet that has transactions
- **THEN** the app offers archiving instead and does not delete the wallet
