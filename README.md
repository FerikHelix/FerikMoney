# FerikMoney

A simple offline-first personal money tracker built with Flutter.

FerikMoney is designed around one short flow: open the app, see all money,
tap **Catat**, record a transaction, and finish. It uses Indonesian labels and
Rupiah amounts, has no login, and does not send financial records to a server.

## Features

- Total balance calculated from account opening balances and transactions
- Cash, bank, e-wallet, and other accounts with safe deletion rules
- Income, expense, and one-record internal transfers
- Fast Rupiah transaction entry with an optional note and date
- Transaction editing and deletion with automatic balance recalculation
- Grouped history with search and month, account, category, and type filters
- Monthly income, expense, net cash flow, and category distribution
- Built-in and custom income/expense categories
- System, light, and dark themes
- Versioned JSON export, sharing, strict validation, and atomic restore
- Friendly empty and error states throughout the application

## UI V3 design system

FerikMoney UI V3 uses centralized tokens in
`lib/app/theme/design_tokens.dart` rather than screen-level color constants.
The refined light palette uses a calm `#F7F9F8` background, layered white and
soft green surfaces, and `#087F5B` brand green. Dark mode retains its
`#0B0F0E` baseline, layered `#141A18` and `#1B2320` surfaces, and selective
`#6EE7B7` mint accent. Income, expense, and transfer each have distinct
semantic colors and soft fills plus signs, arrows, and icons.

Spacing follows a 4/8/12/16/20/24/32 scale. Shared components cover money
text, cards, account cards, section headers, transaction rows, empty states,
the transaction selector, amount input, and expense donut chart. The visibility
control masks money values throughout the app and persists locally.

## Screens

- **Home** — total money, current-month summary, accounts, recent transactions
- **Catat Transaksi** — expense, income, and transfer entry/editor
- **Riwayat** — grouped transaction history, search, and compact filters
- **Statistik** — switchable month summary and category bars
- **Akun Saya** — account balances, account form, and account transactions
- **Pengaturan** — theme, category management, export/import, and app version

## Tech stack

- Flutter 3.41.9 and Dart 3.11.5 through FVM
- Material 3
- GetX for dependency injection, reactive state, and navigation helpers
- Drift on SQLite for local persistence and typed queries
- `shared_preferences` for theme preference
- `file_picker` and `share_plus` for backup files
- `uuid` for locally generated IDs and `intl` for Indonesian formatting

The `drift` and `drift_dev` packages are pinned to 2.34.0 because Flutter
3.41.9 pins a `meta` version that is incompatible with Drift 2.35.0's code
generator. Do not upgrade them independently without rerunning generation,
analysis, and tests.

## Architecture

The application intentionally uses a compact feature-based architecture:

```text
Material UI
    ↓
GetX MoneyController
    ↓
MoneyRepository / BackupService
    ↓
Drift AppDatabase
    ↓
SQLite file on the device
```

SQLite is the source of truth. The controller listens to Drift streams and
exposes the latest accounts, categories, and transactions to the feature
views. Current balances are derived by database queries; no mutable current
balance column is stored.

## Project structure

```text
lib/
├── app/
│   ├── bindings/          # Dependency registration
│   └── theme/             # Material 3 light/dark themes
├── database/              # Drift tables, queries, schema, migrations
├── features/
│   ├── accounts/          # Account list, detail, create/edit
│   ├── home/              # Main glanceable dashboard
│   ├── main/              # Shell and reactive application controller
│   ├── settings/          # Theme, categories, backup/restore
│   ├── statistics/        # Monthly summary and category distribution
│   └── transactions/      # Form, detail, history, filters
├── models/                # Versioned backup DTOs
├── repositories/          # Validated account/category/transaction writes
├── services/              # Backup and theme services
├── utils/                 # Rupiah, date, and icon helpers
├── widgets/               # Shared empty-state and transaction widgets
└── main.dart

test/
├── database/              # Money and balance invariants
├── services/              # JSON validation and atomic rollback
└── money_formatter_test.dart
```

## Flutter and FVM setup

FVM is mandatory and `.fvmrc` pins Flutter 3.41.9.

```bash
fvm use 3.41.9
fvm flutter --version
fvm flutter pub get
```

All Flutter and Dart commands in this repository must be executed through FVM.
Do not upgrade the project beyond Flutter 3.41.9 without an explicit migration.

## Running

```bash
fvm flutter run
```

The Android application ID and corresponding bundle identifier are
`com.ferik.ferikmoney`.

## Drift code generation

The generated file `lib/database/app_database.g.dart` is produced with:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Flutter 3.41.9's current `build_runner` prints a warning that
`--delete-conflicting-outputs` is ignored, but generation still completes.

## Database structure

### `accounts`

`id`, `name`, `type`, `initial_balance`, `icon`, `created_at`, `updated_at`

### `categories`

`id`, `name`, `type`, `icon`, `created_at`

### `transactions`

`id`, `type`, `amount`, `account_id`, nullable `destination_account_id`,
nullable `category_id`, nullable `note`, `transaction_date`, `created_at`,
`updated_at`

Money is always stored as a 64-bit integer Rupiah amount. Transfers are one
transaction: their amount is subtracted from the source and added to the
destination, so they never change total money.

The current schema version is `1`. Future versioned migration steps belong in
`AppDatabase.migration.onUpgrade` in `lib/database/app_database.dart`; never
replace upgrades with destructive database recreation.

## Backup and restore

Export produces a human-readable file such as
`ferikmoney_backup_2026-09-23_10-15.json`:

```json
{
  "version": 1,
  "app": "FerikMoney",
  "exportedAt": "2026-09-23T10:15:00.000+07:00",
  "data": {
    "accounts": [],
    "categories": [],
    "transactions": []
  }
}
```

Import validates the app marker, version, structure, entity types, integer
amounts, dates, duplicate IDs, transaction rules, and every account/category
reference before showing the restore summary. Replacement then runs inside one
Drift transaction. Any failure rolls the whole operation back and leaves the
existing database usable.

## Testing and verification

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```

Tests cover income, expense, both sides of transfers, transfer-neutral total
money, multi-account totals, monthly income/expense/net flow, edits, safe
deletion, Rupiah formatting, JSON serialization, backup validation, missing
references, duplicate IDs, unsupported versions, and restore rollback.

## Privacy

FerikMoney has no authentication, analytics, advertisements, trackers, cloud
database, or network API. Core use is fully offline. Financial records remain
in the device's local SQLite database unless the user explicitly exports or
shares a JSON backup.
