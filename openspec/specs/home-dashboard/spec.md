# home-dashboard Specification

## Purpose

Shows total money, per-wallet balances, current-month totals, and recent entries, with a direct path to add a transaction.

## Requirements

### Requirement: Total balance

Beranda SHALL show the combined current balance of all active wallets, including negative balances, formatted as Indonesian rupiah.

#### Scenario: Combined total
- **WHEN** active wallets hold balances of Rp 100.000, Rp 250.000, and -Rp 50.000
- **THEN** the header shows a total of Rp 300.000

#### Scenario: Archived wallet excluded
- **WHEN** a wallet with a balance is archived
- **THEN** its balance is excluded from the Beranda total while remaining in reports

### Requirement: Wallet overview

Beranda SHALL list every active wallet as a card with its name, type icon, and current balance, and SHALL open that wallet's detail view when tapped.

#### Scenario: Wallet card
- **WHEN** the user taps the "GoPay" card
- **THEN** the wallet detail opens showing its balance and its transactions

#### Scenario: No active wallets
- **WHEN** no active wallet exists
- **THEN** Beranda shows a prompt to create the first wallet instead of an empty card list

### Requirement: Monthly snapshot

Beranda SHALL show the current month's total income, total expense, and net difference, consistent with the analytics definition that excludes transfers and includes transfer fees.

#### Scenario: Snapshot values
- **WHEN** the current month has Rp 3.000.000 income and Rp 1.200.000 expense
- **THEN** Beranda shows Rp 3.000.000 income, Rp 1.200.000 expense, and Rp 1.800.000 net

### Requirement: Recent activity

Beranda SHALL show the most recent transactions with category icon, note or category name, wallet, date, and signed amount, and SHALL offer a path to the full history.

#### Scenario: Recent list
- **WHEN** ten or more transactions exist
- **THEN** Beranda shows a bounded recent list and a "Lihat semua" action opening full history

### Requirement: Quick entry

Beranda SHALL show a persistent add action that stays visible without scrolling. It SHALL default to an expense and offer income and transfer options, each opening the matching form.

#### Scenario: Add expense
- **WHEN** the user taps the primary add action
- **THEN** the expense form opens with the amount field focused, the numeric keyboard shown, and today's date selected

#### Scenario: Add transfer from quick entry
- **WHEN** the user chooses the transfer action
- **THEN** the transfer form opens with no wallets preselected

#### Scenario: Save in three taps
- **WHEN** the user taps add, enters an amount, and taps save
- **THEN** the expense is saved with the preselected wallet and category, without opening another screen or dialog

### Requirement: Subscription banner placement

When a subscription reminder is due, Beranda SHALL show it above the total balance area as a dismissible Material 3 banner that opens the subscription list.

#### Scenario: Banner visible
- **WHEN** a subscription enters its reminder window
- **THEN** the banner appears at the top of Beranda and remains reachable without scrolling past the wallet list

### Requirement: Dashboard refresh

Beranda SHALL reflect saved changes immediately, without requiring a manual refresh or app restart.

#### Scenario: New expense updates dashboard
- **WHEN** the user saves an expense and returns to Beranda
- **THEN** the total, wallet card, monthly snapshot, and recent list already include it
