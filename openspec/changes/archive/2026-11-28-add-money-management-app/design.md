# Design

## Context

FerikMoney is a greenfield Android app. There is no existing code, database, or release history to preserve. The repository currently contains only OpenSpec artifacts.

Constraints that shape the approach:

- **Toolchain**: Flutter 3.50.1 stable (Dart 3.14.0) pinned with FVM 4.1.0. The machine has no global Flutter, so every command runs through `fvm flutter`.
- **Platform**: Android only for v1; no iOS, desktop, or web.
- **Offline**: no account, no backend, no telemetry. Data lives on the device.
- **Currency**: Indonesian rupiah only, whole amounts, no decimals.
- **Scope**: see `proposal.md`; behavior is defined by the seven capability specs under `specs/`.

## Goals / Non-Goals

**Goals:**

- A project that runs immediately after checkout with `fvm flutter run`.
- Wallet balances derived from immutable ledger facts, so they cannot drift out of sync.
- Expense entry in three taps from Beranda: add, amount, save. The amount field is focused and the wallet and category are already selected.
- Clear separation between the real ledger and the debt ledger until an explicit commit.
- Material 3 presentation with full Material Symbols coverage, 48 dp targets, and layouts that hold at 200% text scale.
- Short Indonesian copy that states the action or fact without filler.

**Non-Goals:**

- Cloud sync, authentication, multi-device, or bank integrations.
- OS-level notifications, background jobs, or auto-posting subscriptions.
- Multi-currency, budgets, attachments, or data export/import.
- App lock, database encryption, or obfuscation in v1 (device security only).
- Riverpod/Freezed code generation; keep state code explicit.

## Decisions

### D1. Pin Flutter with FVM and commit `.fvmrc`

Use `fvm use 3.50.1` so `.fvmrc` becomes the single source of truth. Commit `.fvmrc`, `pubspec.lock`, and generated Drift files; ignore `.fvm/` (the SDK link) and build output.

- **Why**: every contributor and CI run uses the same SDK; no reliance on a global Flutter install.
- **Alternative considered**: `flutter` channel tracking or a Docker image. Rejected for slower setup and no Android emulator integration on this machine.

### D2. Feature-first structure with a shared core

```
lib/
  main.dart
  app/            # app widget, router, theme, localization wiring
  core/
    db/           # Drift database, tables, DAOs
    money/        # rupiah parsing, formatting, validators
    dates/        # local date keys, month ranges
    widgets/      # shared Material 3 widgets and states
  features/
    home/         # dashboard
    wallets/      # kantong
    transactions/ # income, expense, transfer, history
    analytics/
    subscriptions/
    debts/
    settings/
```

Each feature has `presentation/` and, where needed, `data/` and `domain/`. Cross-feature reads go through DAOs or read-only providers; features do not reach into each other's widgets.

- **Why**: seven capabilities share one database and theme; a feature-first layout keeps each spec traceable to one folder.
- **Alternative considered**: layer-first (`data/`, `domain/`, `presentation/` at top). Rejected because a money app changes per feature, not per layer.

### D3. Riverpod (manual providers) for state

Use `flutter_riverpod` with hand-written `Provider`, `StreamProvider`, `AsyncNotifier`, and `Notifier`. No `riverpod_generator`, `freezed`, or `build_runner` for state classes.

- **Why**: Drift already requires `build_runner`; adding a second codegen pipeline increases churn without much benefit at this size. Manual providers are easy to trace and test.
- **Alternative considered**: Bloc. Rejected because stream-backed database reads map naturally to `StreamProvider`, and the app has little event-driven complexity.

Reactivity: DAOs expose Drift `watch()` queries; UI consumes `AsyncValue` and renders loading, error, and empty states explicitly. Mutations run through controllers that disable submit while pending.

### D4. Drift + SQLite, with balances derived, not stored

Schema v1 (all amounts `INTEGER` rupiah, all dates `TEXT` as `YYYY-MM-DD`):

- `wallets`: `id`, `name`, `type` (`cash|bank|ewallet|other`), `opening_balance`, `icon_code_point`, `color_value`, `sort_order`, `archived_at`, timestamps.
- `categories`: `id`, `name`, `kind` (`income|expense`), `icon_code_point`, `color_value`, `is_system`, `archived_at`, timestamps.
- `transactions`: `id`, `kind` (`income|expense`), `amount`, `wallet_id`, `category_id`, `date`, `note`, timestamps.
- `transfers`: `id`, `source_wallet_id`, `destination_wallet_id`, `amount`, `fee` (default 0), `date`, `note`, timestamps.
- `subscriptions`: `id`, `name`, `amount`, `wallet_id`, `category_id`, `cycle` (`monthly|yearly`), `anchor_day`, `anchor_month`, `lead_days`, `next_due_date`, `active`, `note`, timestamps.
- `debt_entries`: `id`, `direction` (`utang|piutang`), `counterparty`, `principal`, `start_date`, `due_date`, `note`, `principal_transaction_id`, timestamps.
- `debt_payments`: `id`, `debt_id` (cascade), `amount`, `date`, `note`, `transaction_id`, timestamps.
- `settings`: `key` primary key, `value`.

Balance is always computed:

```
wallet balance = opening_balance
  + SUM(income transactions)
  - SUM(expense transactions)
  - SUM(outgoing transfer amount + fee)
  + SUM(incoming transfer amount)
```

- **Why derived balances**: edit and delete cannot leave a stale cached number; every write is a single Drift transaction. Personal-scale data makes aggregate queries cheap with indexes.
- **Alternative considered**: a cached `balance` column updated by triggers. Faster reads, but migration, repair, and concurrency risks outweigh the gain here.
- **Alternative considered**: a double-entry postings table. More correct for accounting, but overkill for a personal wallet app and much harder to explain in the UI.

Transfers are one row, not two or three synthetic transactions. This keeps a transfer atomic and editable as a unit; the fee is a reporting construct, not a separate ledger entry.

Indexes: `transactions(wallet_id, date)`, `transactions(category_id, date)`, `transfers(source_wallet_id, date)`, `transfers(destination_wallet_id, date)`, `subscriptions(next_due_date)`, `debt_entries(direction, due_date)`, `debt_payments(debt_id)`.

DAOs that aggregate across tables use `customSelect(...).watch()` with `readsFrom` listing every table involved, so dashboards refresh when any relevant write lands.

### D5. Local date keys, no time zones

Dates are stored as `YYYY-MM-DD` strings and converted to `DateTime(y, m, d)` in local time. Month queries use half-open ranges `[first of month, first of next month)`.

- **Why**: a transaction is a calendar event, not an instant. String keys avoid UTC offset shifts and make SQL grouping trivial.
- **Alternative considered**: SQLite `DateTime` stored as UTC epoch. Rejected because a 23:00 entry can display as the next day after a time zone change.
- **Alternative considered**: epoch-day integers. Compact, but unreadable in debugging and no real benefit.

### D6. Money as integer rupiah

No `double` anywhere in domain or storage. Input fields strip grouping separators, accept digits only, and parse to `int`. Formatting uses `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`.

- **Why**: rupiah has no practical subunit; integers avoid floating-point drift.
- **Alternative considered**: store cents as `int`. Rejected as unused precision and an easy source of factor-of-100 bugs.
- **Limit**: `999_999_999_999` per entry, validated before save.

### D7. Material 3 theme and Material Symbols

Use `ColorScheme.fromSeed` with a deep green seed (`#006C4C`), `useMaterial3: true`, and a `NavigationBar` with five destinations inside `StatefulShellRoute.indexedStack`. Forms open as full-screen routes; confirmations use M3 dialogs; quick choices use bottom sheets. Use the `material_symbols_icons` package with `MaterialSymbolsRounded`.

- **Why**: Rounded Material Symbols share the stroke weight of M3 shapes, and the package provides the complete symbol set offline.
- **Risk**: the package bundles several font families (APK size). Verify with `--analyze-size`; if the size cost is unacceptable, subset the variable font to used codepoints and declare a local font asset instead.
- **Alternative considered**: built-in `Icons` (Material Icons). Rejected because the user explicitly asked for Material Symbols coverage.
- **Alternative considered**: Android 12 dynamic color. Deferred; it complicates brand consistency and screenshot testing.

Component map:

| Need | Component |
| --- | --- |
| Top-level navigation | `NavigationBar` |
| Add action | `FloatingActionButton` on Beranda |
| Save / primary action | `FilledButton` in a pinned bottom bar |
| Secondary action | `OutlinedButton` or `TextButton` |
| Wallets and summaries | `Card` with `ListTile` rows |
| Month and wallet filters | `SegmentedButton` and `FilterChip` |
| Wallet, category, date pickers | `ModalBottomSheet` / Material date picker |
| Destructive confirmation | `AlertDialog` with an error-colored action |
| Save feedback | `SnackBar` |

Layout: 16 dp screen margins on an 8 dp spacing grid, 48×48 dp minimum targets, single-column forms, and a 600 dp maximum content width centered on tablets. The save bar stays above the keyboard; forms scroll behind it instead of resizing into overflow.

Typography and color roles stay on M3 defaults (`displaySmall`, `titleMedium`, `bodyMedium`, `labelLarge`) with rupiah amounts using tabular figures where available.

### D8. Localization and formatting

Enable `flutter_localizations`, set `supportedLocales: [Locale('id')]` and `locale: Locale('id')`. Use ARB files (`lib/l10n/app_id.arb`) with `flutter gen-l10n`, even though v1 is Indonesian-only, so English can be added later without rewiring.

Dates: `DateFormat('d MMM yyyy', 'id_ID')`; date pickers use the Indonesian Material localization. All user-facing strings come from ARB; no hard-coded Indonesian text in widgets.

### D9. Navigation flow

`go_router` routes:

- `/` shell with `/home`, `/wallets`, `/analytics`, `/subscriptions`, `/debts`.
- `/wallets/new`, `/wallets/:id`, `/wallets/:id/edit`.
- `/transactions/new?type=expense|income|transfer`, `/transactions/:id/edit`, `/transactions` (history).
- `/subscriptions/new`, `/subscriptions/:id/edit`.
- `/debts/new`, `/debts/:id`, `/debts/:id/payment`.
- `/settings`.

A first-run guard checks wallet count: zero wallets routes to `/wallets/new?firstRun=true`; the form is skippable, and the home empty state plus quick-entry actions route back to wallet creation. Saving any money movement without a wallet is impossible because pickers are empty and controllers reject the write.

### D10. Dashboard and analytics queries

- **Total**: sum of derived balances for active wallets only. Archived wallets stay out of the Beranda total but remain in analytics history.
- **Monthly snapshot**: income = sum of income transactions; expense = sum of expense transactions plus transfer fees; net = income − expense. Transfers themselves are excluded.
- **Category breakdown**: expenses grouped by category, plus a synthetic "Biaya Transfer" slice from `SUM(transfers.fee)`; income grouped separately. Archived categories keep their names.
- **Trend**: six calendar months ending at the selected month, generated app-side as six range queries or one grouped query with a calendar CTE; missing months become zeros.
- **Wallet filter**: adds `wallet_id` / source-destination predicates; archived wallets are selectable.
- **Empty month**: return a typed empty result so the UI can show an explanation instead of zero charts.

### D11. Subscription due-date engine

Store `anchor_day` (and `anchor_month` for yearly) plus `next_due_date`. Compute a due date for a target month with `min(anchor_day, daysInMonth)`. After payment or skip, advance one cycle **from the due date that was settled**, using the anchor day, so a 31st subscription returns to the 31st after February instead of drifting to the 28th. Leap-day yearly subscriptions use 28 February in non-leap years.

Due query: `active = 1 AND next_due_date <= today + lead_days`. Dismissals live in an in-memory Riverpod `Set<int>` cleared when the process restarts, matching "until the next app launch". Paying opens the expense form prefilled; the subscription is updated in the same Drift transaction that inserts the expense, only after the user saves.

### D12. Debt ledger and commit

`debt_entries.principal_transaction_id` and `debt_payments.transaction_id` are nullable FKs with `ON DELETE SET NULL`. A commit is optional at creation and at payment time; choosing a wallet and category creates the transaction in the same Drift transaction as the ledger write.

Direction mapping:

| Ledger event | Committed transaction |
| --- | --- |
| Utang principal received | income |
| Utang repayment made | expense |
| Piutang principal lent | expense |
| Piutang repayment received | income |

A unique partial index on each link column (where not null) prevents double-commit if a write is retried. Deleting a linked transaction nulls the link, making the entry committable again. Ledger amounts remain the source of truth even if the linked transaction is later edited; the link records the original cash movement.

### D13. Validation and idempotent saves

Controllers validate amount > 0 and ≤ limit, wallet active, category kind matches transaction kind, source ≠ destination, date ≤ today, payment ≤ remaining, and active wallet existence. Validation runs when a field loses focus and again on save; messages render as supporting text under the field. Submit buttons are disabled while a save is in flight. Each save is one Drift `transaction()`; there is no retry queue, and a failure returns a typed error that the form displays without discarding input.

### D14. Testing strategy

- **Unit**: rupiah parse/format, date month ranges, due-date clamping and anchor advancement, balance effects, debt commit direction mapping, transfer fee totals.
- **DAO**: in-memory SQLite (`NativeDatabase.memory()`), covering balance derivation, archive behavior, analytics aggregation, and link clearing.
- **Widget**: dashboard empty states, form validation messages, subscription banner visibility, debt commit toggle, 360 dp layout, 200% text scale, and an ARB scan for exclamation marks and emoji.
- **Manual**: Android emulator/device smoke test for keyboard behavior, back navigation, dark mode, and one-handed reach.

Generated Drift files are committed so a fresh checkout runs without `build_runner`; CI still runs `fvm flutter pub run build_runner build --delete-conflicting-outputs` to verify they are current.

### D15. Interaction and copy rules

- **Entry path**: the Beranda FAB opens the expense form with the amount field focused and the numeric keyboard shown. Wallet and category come from the last saved entry of that kind, falling back to the first active wallet and first category. Saving pops back and shows a snackbar; the save path never opens a dialog.
- **Transfers**: no wallet is preselected; source and destination use separate bottom sheets; the optional fee starts empty.
- **Feedback**: field errors use supporting text, success uses a snackbar, storage failure keeps the form and offers retry. Field errors never appear in a dialog.
- **Confirmations**: destructive actions (delete, discard unsaved changes) and negative-balance overrides ask first. Routine saves and edits do not.
- **Copy**: all strings live in `app_id.arb`. Sentence case, verb-first actions, errors state cause and fix. No exclamation marks, emoji, filler, or blame. Empty states use one factual sentence and one action. Amounts are always written as `Rp` values, never abbreviations such as "5jt".
- **Accessibility**: icon-only controls get `Semantics` labels, amounts are announced with sign and context, charts always carry text labels, and the 200% text test runs at 360 dp.

## Risks / Trade-offs

- **Material Symbols package size** → measure the release APK early; fall back to a subset font asset if needed.
- **Derived balances get slower with volume** → personal scale and targeted indexes keep queries sub-millisecond for tens of thousands of rows; if it ever matters, add a cached balance with triggers in a later change.
- **Transfer fee as a synthetic category** → users cannot re-categorize a fee; acceptable because the spec only requires it to count as an expense. Revisit if users ask for fee categories.
- **Negative balances allowed** → totals can look alarming; use explicit warning color and a short explanation on first negative occurrence.
- **No app lock or encryption** → local SQLite is readable on a rooted/compromised device. Document as a v1 limitation; app lock is the first candidate for a follow-up change.
- **Copy drifts back into widgets** → all strings stay in ARB, and a test scans for exclamation marks and emoji. Review new copy against D15 during pull requests.
- **Manual providers** → more boilerplate than codegen, but fewer moving parts and no generated state files.
- **Future-dated transactions blocked** → users cannot pre-log a planned expense; subscriptions and debt notes cover planned obligations. Revisit if requested.
- **Windows development host** → Android builds depend on the local Android SDK/JDK; tasks include a `flutter doctor` gate before feature work.

## Migration Plan

Greenfield, so there is no data migration at launch.

1. `fvm use 3.50.1`, create the Flutter project, then verify `fvm flutter doctor` and an Android debug build.
2. Ship schema `schemaVersion = 1` with `onCreate` seeding default categories and the system "Biaya Transfer" category. No default wallet is seeded; first-run setup creates it.
3. Commit `.fvmrc`, `pubspec.lock`, and Drift generated files. Ignore `.fvm/`, build output, and local properties.
4. Rollback strategy for v1 is uninstall/reinstall (data loss). There is no cloud copy by design.
5. Before the first public release, enable Drift schema export and add migration tests so v2 has a verified upgrade path.

## Open Questions

- Brand assets (launcher icon, splash, final seed color) are not specified; v1 can ship with the green seed and a placeholder icon, then a later change can add branding.
- Whether a future release adds app lock/biometric and database encryption is deferred to a separate change.
- English localization is structurally supported but not required in v1.
