# Spec Delta

## Purpose

Summarizes monthly income, expense, category shares, and six-month trends, with a wallet filter.

## ADDED Requirements

### Requirement: Month selection

Analytics SHALL open on the current month and SHALL let the user move to any earlier or later month that has data.

#### Scenario: Change month
- **WHEN** the user selects the previous month
- **THEN** every chart and total updates to that month's data

#### Scenario: Current month default
- **WHEN** the user opens analytics
- **THEN** the current month is selected

### Requirement: Monthly summary

For the selected month the app SHALL show total income, total expense, and net difference in rupiah, calculated from posted transactions only.

#### Scenario: Summary values
- **WHEN** the selected month has Rp 5.000.000 income and Rp 2.000.000 expense
- **THEN** the summary shows income Rp 5.000.000, expense Rp 2.000.000, and net Rp 3.000.000

### Requirement: Transfers excluded

Transfers between wallets SHALL NOT contribute to income, expense, or category breakdowns. Transfer fees SHALL count as expenses.

#### Scenario: Month with only transfers
- **WHEN** the month contains only wallet-to-wallet transfers
- **THEN** income and expense totals show Rp 0 and the transfer amounts do not appear

### Requirement: Category breakdown

The app SHALL group the selected month's expenses by category and the month's income by category, showing each category's name, amount, and percentage of its total as text, sorted from largest to smallest. Color SHALL NOT be the only way to distinguish categories.

#### Scenario: Expense breakdown
- **WHEN** "Makan" is Rp 600.000 and "Transport" is Rp 400.000 of a Rp 1.000.000 expense month
- **THEN** the breakdown lists Makan at Rp 600.000 (60%) and Transport at Rp 400.000 (40%)

#### Scenario: Use of archived categories
- **WHEN** a transaction belongs to an archived category
- **THEN** the breakdown still includes it under that category's name

#### Scenario: Text labels
- **WHEN** the user reads or screens a category row
- **THEN** the row states the category name, amount, and percentage without relying on its color

### Requirement: Monthly trend

The app SHALL chart income and expense for the six months ending with the selected month, preserving months with no transactions as zero values.

#### Scenario: Trend window
- **WHEN** the user selects June 2026
- **THEN** the trend shows January through June 2026

#### Scenario: Empty month in the window
- **WHEN** one of the six months has no transactions
- **THEN** that month appears with zero income and zero expense instead of being omitted

### Requirement: Wallet filter

Analytics SHALL offer an all-wallets view and a single-wallet view, including archived wallets, and every total and chart SHALL respect the selection.

#### Scenario: Filter by wallet
- **WHEN** the user filters analytics to wallet "GoPay"
- **THEN** the summary, breakdown, and trend use only that wallet's transactions

### Requirement: Empty analytics state

When the selected month has no transactions, the app SHALL show an explanatory empty state rather than empty or misleading charts.

#### Scenario: Empty month
- **WHEN** the user selects a month with no transactions
- **THEN** the app states that there is no data for that month and suggests recording a transaction
