# FerikMoney

FerikMoney is a private, offline-first personal money manager built with Flutter. It keeps everyday expense entry fast while making budgets, recurring transactions, savings goals, and useful reports available one layer deeper.

## Features

- Four primary tabs: **Home, Transaksi, Laporan, Lainnya**
- Wallets for cash, bank, e-wallet, savings, and other account types
- Income, expenses, and wallet-to-wallet transfers stored as integer minor units
- Fast transaction form with expense as the default and optional note, time, and tags under **Detail lainnya**
- Quick Add, frequent categories, remembered wallet/category, date shortcuts, duplicate, edit, delete, and undo
- Search across notes, categories, wallets, and tags; filters and four sorting modes
- Archive-safe wallets and categories that preserve historical records
- Optional overall and per-category monthly budgets
- Daily, weekly, monthly, and yearly recurring rules with idempotent pending occurrences whose amount and transaction details can be adjusted before confirmation
- Savings goals with deposits and withdrawals that preserve total wealth
- Weekly, monthly, and yearly reports with category totals, trend, top categories, and local insights
- System/light/dark themes and privacy masking for money values
- IDR, USD, SGD, MYR, THB, and JPY formatting with integer minor-unit storage
- Versioned JSON backup/restore, backward-compatible v1 import, CSV transaction export, and local reset
- Friendly empty, loading, and error states

## Product and privacy

The normal flow is: open the app, see all money, tap **+**, enter an amount, choose a category and wallet, then save. There is no login, cloud backend, analytics, advertising, tracking, bank API, or internet dependency. Financial data remains in the local SQLite database unless the user explicitly exports it.

## Tech stack

- Flutter 3.41.9 and Dart through FVM
- Material 3
- GetX for dependency injection, navigation, and reactive controllers
- Drift 2.34.0 over SQLite
- `shared_preferences` for local preferences
- `file_picker` and `share_plus` for JSON/CSV files
- `uuid` and `intl`

Drift is pinned to 2.34.0 for compatibility with the SDK constraints used by Flutter 3.41.9.

## Architecture

```text
Material UI
  -> feature GetX controllers
  -> repositories and local services
  -> Drift AppDatabase
  -> SQLite on the device
```

`MoneyController` owns the core wallet/category/transaction state. Budget, Recurring, Savings, and Reports use focused controllers and repositories. SQLite remains the source of truth; current balances and goal progress are calculated from stored events instead of mutable balance fields.

## Main folders

```text
lib/
  app/                 dependency bindings and Material themes
  database/            Drift schema, queries, migration, generated code
  features/
    accounts/          wallet list, detail, create/edit/archive
    budgets/           monthly budgets and progress
    home/              overview, period selector, quick add, activity
    main/              four-tab shell and core controller
    more/              secondary feature navigation
    recurring/         rules and pending occurrence review
    reports/           weekly/monthly/yearly reports
    savings/           goals and wallet transfers
    settings/          preferences, categories, backup, CSV, reset
    transactions/      add/edit/detail/history/search/filter/sort
  models/              domain value types and backup DTOs
  repositories/        validated feature persistence
  services/            preferences, currency, privacy, theme, backup
  widgets/             shared finance UI components
test/
  database/            balance, archive, budget, goal, recurring invariants
  services/            backup, preferences, currency, theme
  widgets/             responsive component and application smoke tests
```

## Database schema and migration

The current Drift schema version is **2**. The v1 to v2 migration is implemented in `AppDatabase.migration.onUpgrade` and preserves existing IDs, balances, categories, and transactions.

Tables:

- `accounts`: wallet details plus `is_archived`
- `categories`: income/expense categories plus `is_archived`
- `transactions`: income, expense, or one-record wallet transfer
- `tags` and `transaction_tags`
- `budgets`
- `recurring_rules`, `recurring_rule_tags`, and `recurring_occurrences`
- `savings_goals` and `savings_goal_transfers`

Money is stored as a 64-bit integer in the selected currency's minor unit. For example, IDR 25,000 is `25000`, while USD 123.45 is `12345`.

A savings deposit subtracts from its wallet and adds the same amount to the goal. A withdrawal reverses it. Consequently:

```text
Total Uang = wallet balances + savings goal balances
```

Internal wallet transfers and savings transfers never change total wealth.

## Backup, restore, CSV, and reset

JSON backup format v2 includes all database collections and preferences. Import accepts both v1 and v2. Before replacement, FerikMoney validates IDs, types, integer amounts, dates, uniqueness constraints, and every foreign-key reference. Database replacement runs inside one Drift transaction, so a failure rolls back the complete restore.

Repeated restores are detected using backup version and entity ID collections, and the confirmation dialog shows an extra warning. CSV export includes ISO date/time, type, integer minor-unit amount, currency, wallet, destination, category, tags, and note. Reset removes financial data, reseeds default categories, clears financial preferences, and retains theme settings.

## FVM setup and running

`.fvmrc` pins Flutter 3.41.9. Always run Flutter and Dart commands through FVM:

```bash
fvm use 3.41.9
fvm flutter --version
fvm flutter pub get
fvm flutter run
```

Android application ID: `com.ferik.ferikmoney`.

## Drift generation

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

The current `build_runner` may report that `--delete-conflicting-outputs` is ignored; generation still completes normally.

## Verification

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
```

The test suite covers balance invariants, transaction validation, archive safety, tags, budget thresholds, savings total invariance, recurring idempotency, currency minor units, backup v1 compatibility, backup v2 round trips, atomic rollback, responsive widgets, and the four-tab application shell.
