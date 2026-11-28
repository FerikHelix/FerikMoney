# Proposal

## Why

FerikMoney is a personal money app for Android that works without an account or a network. It records income, expenses, and transfers across cash, bank, and e-wallet balances ("kantong"), summarizes each month, and reminds the user about subscriptions without posting charges on its own. Existing options either require connectivity or make routine entry slow; this app uses one wallet model and short forms.

## What Changes

- Create a new Flutter app pinned with FVM to Flutter 3.50.1 (stable), Android-only for v1.
- Add **kantong** (wallet) management: cash, bank, e-wallet, and other wallets with opening balance, icon, color, and archive.
- Add income and expense recording against a kantong and category, plus transfers between kantong with an optional admin fee.
- Add a home dashboard: total balance, per-kantong balances, current-month income/expense, due-subscription banner, and recent transactions.
- Add analytics: month picker, income vs expense, category breakdown, monthly trend, and filter by kantong.
- Add **langganan** (subscription) reminders: user-defined monthly/yearly subscriptions, a banner when due, and one-tap prefilled expense; never auto-posted.
- Add **utang/piutang** (debt/receivable) notes tracked in a separate ledger with partial payments; balances are unaffected until the user explicitly commits an entry to the main money.
- Apply Material 3 with Material Symbols throughout, light/dark themes, and Indonesian-language, IDR-only formatting.
- Design for one-handed use: a persistent add action, forms that open with the amount field focused and the last-used wallet and category selected, inline validation, and confirmations only for destructive actions.
- Use short Indonesian copy in sentence case, with no filler, exclamation marks, or emoji.
- Persist everything locally with an embedded database; no login, no network, no cloud sync.

Out of scope for this change: iOS/desktop/web targets, cloud sync and multi-device, bank/e-wallet integrations, multi-currency, budgets/spending limits, attachments, and automatic recurring posting.

## Capabilities

### New Capabilities

- `app-foundation`: offline-first local persistence, app shell and navigation, Material 3 theming, interaction and copy rules, and durable settings.
- `home-dashboard`: total and per-wallet balances, monthly snapshot, recent activity, and quick entry.
- `kantong-management`: create, edit, archive, and list wallets with types and balances.
- `transactions`: record, edit, and delete income/expense entries, transfers between wallets, and category management.
- `analytics`: monthly income/expense summaries, category breakdown, trends, and per-wallet filtering.
- `subscriptions`: subscription definitions, due reminders on the home screen, and one-tap expense creation.
- `debt-ledger`: utang/piutang notes, partial payments, and explicit commit to the main ledger.

### Modified Capabilities

None. This is a greenfield project.

## Impact

- New Flutter project at the repository root: `pubspec.yaml`, `lib/`, `test/`, `android/`, plus `.fvmrc`/`.fvm/` pinning Flutter 3.50.1.
- Runtime dependencies: `flutter_riverpod`, `drift` + `drift_flutter`, `go_router`, `intl`, `material_symbols_icons`, and `flutter_localizations`.
- Local SQLite database with versioned migrations; all data stays on device.
- No backend, no authentication service, no analytics/telemetry.
