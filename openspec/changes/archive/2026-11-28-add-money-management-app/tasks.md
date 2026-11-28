# Tasks

## 1. Toolchain and project scaffold

- [x] 1.1 Pin Flutter 3.50.1 with `fvm use 3.50.1 --force`, commit `.fvmrc`, and add `.fvm/`, `build/`, and `android/local.properties` to `.gitignore`; verify `fvm flutter --version` reports 3.50.1.
- [x] 1.2 Initialize git, then create the Android-only Flutter project in place with `fvm flutter create --platforms=android --org com.ferik --project-name ferik_money .`; verify `fvm flutter doctor` is clean and an Android debug build installs on an emulator.
- [x] 1.3 Add runtime dependencies (`flutter_riverpod`, `drift`, `drift_flutter`, `go_router`, `intl`, `material_symbols_icons`, `flutter_localizations`) and dev dependencies (`drift_dev`, `build_runner`, `flutter_lints`, `sqlite3`); verify `fvm flutter pub get` succeeds.
- [x] 1.4 Create the `lib/app`, `lib/core`, and `lib/features/*` structure from design D2 and enable strict lints in `analysis_options.yaml`; verify `fvm flutter analyze` reports no issues on the empty scaffold.
- [x] 1.5 Set up Indonesian localization with `flutter gen-l10n`, `supportedLocales: [Locale('id')]`, and an initial ARB file; verify the generated `AppLocalizations` is usable in a widget test.
- [x] 1.6 Implement the Material 3 theme with the `#006C4C` seed, light/dark/system modes, and `MaterialSymbolsRounded`; verify a widget test renders both brightnesses without overflow.
- [x] 1.7 Add the shared layout and copy rules from design D15: 16 dp margins, 48 dp targets, a pinned save bar, and ARB-only strings; verify a test scans `app_id.arb` for exclamation marks and emoji and finds none.

## 2. Data layer

- [x] 2.1 Define the Drift tables from design D4 (`wallets`, `categories`, `transactions`, `transfers`, `subscriptions`, `debt_entries`, `debt_payments`, `settings`) with keys, indexes, and cascade/set-null rules; verify `build_runner` generates the database code and `fvm flutter analyze` passes.
- [x] 2.2 Implement schema version 1 with `onCreate` seeding default income/expense categories and the system "Biaya Transfer" category; verify a DAO test opens an in-memory database and finds the seeds exactly once.
- [x] 2.3 Implement wallet DAOs: create/rename/archive/delete guards, case-insensitive active-name check, and the derived-balance query covering income, expense, transfers, and fees; verify DAO tests match the balance scenarios in `kantong-management` and `transactions`.
- [x] 2.4 Implement transaction and transfer DAOs with atomic create/update/delete and the same-wallet and date guards; verify DAO tests confirm balances after edits, deletes, and transfers.
- [x] 2.5 Implement analytics DAO queries for monthly totals, category breakdown (including the synthetic transfer-fee slice), six-month trend, and wallet filter; verify DAO tests cover transfers-excluded and archived-category-included cases.
- [x] 2.6 Implement subscription and debt DAOs, including due queries, partial payments, overdue calculation, summary totals, and nullable commit links; verify DAO tests cover overpayment rejection and link clearing on transaction delete.
- [x] 2.7 Implement the settings DAO for theme mode and add money/date utility unit tests (rupiah parse/format, amount limits, month ranges, date keys); verify `fvm flutter test test/core` passes.

## 3. App shell and first run

- [x] 3.1 Implement `go_router` with `StatefulShellRoute.indexedStack` and the five destinations; verify a widget test switches tabs and preserves each tab's state.
- [x] 3.2 Implement the first-run guard and first-wallet flow, including the skippable welcome state and empty-dashboard prompt; verify widget tests cover zero-wallet routing and post-creation navigation to Beranda.
- [x] 3.3 Implement the settings screen with theme selection and an about/version entry; verify a widget test changes the theme and a restart test reads the persisted value.

## 4. Kantong (wallets)

- [x] 4.1 Build the wallet list with type icons, balances, negative-balance warning treatment, and archived grouping; verify widget tests cover normal, negative, and archived states.
- [x] 4.2 Build the create/edit wallet form with name validation, type picker, opening balance input, icon and color pickers; the create form starts with the name focused and Tunai selected; verify widget tests cover duplicate names, defaults, and opening-balance edits.
- [x] 4.3 Implement archive and delete actions with the last-active-wallet and history guards; verify DAO/widget tests for each guard and the archive-from-picker behavior.
- [x] 4.4 Build wallet detail with balance and its transaction history; verify a widget test opens a wallet card and shows only that wallet's entries.

## 5. Transactions and transfers

- [x] 5.1 Build the expense form with amount, wallet, category, date, and note, including autofocus on amount, numeric keyboard, grouping while typing, last-used defaults, validation, and submit locking; verify widget tests cover valid save, zero/oversized amounts, future dates, pasted amounts, and the archived-wallet fallback.
- [x] 5.2 Build the income form by reusing the transaction form with income categories and the income balance effect; verify widget tests cover save and edit.
- [x] 5.3 Add category management: default list, create, rename, and archive with historical retention; verify widget tests archive a used category and still see it in history.
- [x] 5.4 Build the transfer form with source, destination, amount, optional fee, date, and negative-balance confirmation; verify widget tests block same-wallet transfers and confirm fee totals.
- [x] 5.5 Build transaction history grouped by date with edit and confirmed delete; verify widget tests cover grouping, deletion reversal, a one-sentence empty state, and the snackbar after save.
- [x] 5.6 Implement transfer editing/deletion as a single unit and verify DAO tests keep both wallet balances correct after each change.

## 6. Beranda dashboard

- [x] 6.1 Implement the total balance header, active-wallet cards, and archived-wallet exclusion; verify widget tests with mixed and negative balances.
- [x] 6.2 Implement the current-month snapshot and recent activity list with "Lihat semua"; verify widget tests cover values, bounded list, and empty states.
- [x] 6.3 Wire quick entry for expense, income, and transfer with the correct presets, amount focus, and keyboard; verify a widget test reaches a saved expense in add → amount → save without another screen or dialog.
- [x] 6.4 Integrate the subscription reminder banner above the totals with dismissal for the session; verify widget tests for due, not-due, and dismissed states.
- [x] 6.5 Verify dashboard reactivity: save an expense in a DAO test, then confirm the watched dashboard query emits updated totals without manual refresh.

## 7. Analytics

- [x] 7.1 Build the month selector and summary cards for income, expense, and net; verify widget tests change months and display the correct values.
- [x] 7.2 Build the category breakdown for expenses and income with name, amount, and percentage in text, including archived-category names; verify widget tests cover sorting, percentages, the transfer-fee slice, and readability without color.
- [x] 7.3 Build the six-month trend chart with zero-filled empty months; verify widget tests cover the six-month window and an empty month.
- [x] 7.4 Add the all-wallets/single-wallet filter including archived wallets; verify widget tests confirm every section respects the filter.
- [x] 7.5 Add the empty-month state and verify it replaces charts with an explanation and add action.

## 8. Subscriptions

- [x] 8.1 Build the subscription list and create/edit form with amount, wallet, category, cycle, due day/month, lead days, and active toggle; verify widget tests cover invalid due days and saved values.
- [x] 8.2 Implement the due-date engine with month-end clamping, leap-day handling, and anchor-based advancement; verify unit tests cover 31st, 29 February, and late payment without drift.
- [x] 8.3 Implement the pay flow that prefills an expense, advances only after save, and preserves the subscription amount when the user edits the expense; verify widget tests for confirm, cancel, and adjusted amount.
- [x] 8.4 Implement skip-cycle and deactivate actions with confirmation; verify widget tests confirm due-date movement without a transaction and that inactive subscriptions leave the banner.
- [x] 8.5 Verify reminders are in-app only: confirm no notification scheduling dependency or permission exists and the banner appears on next launch after dismissal.

## 9. Debt ledger

- [x] 9.1 Build the debt list with separate utang/piutang totals, open/settled/overdue status, and empty states; verify widget tests cover mixed directions and overdue entries.
- [x] 9.2 Build the create/detail flow for utang and piutang with counterparty, principal, dates, and note; verify widget tests cover required fields and saved values.
- [x] 9.3 Implement partial payments with remaining calculation, overpayment rejection, and settled state; verify widget tests cover partial, full, and excessive payments.
- [x] 9.4 Implement the optional commit flow with wallet/category selection, the direction mapping table, and a label that names the wallet and resulting income/expense; verify DAO tests confirm all four directions and widget tests confirm the label text.
- [x] 9.5 Implement single-commit enforcement and link clearing on transaction deletion; verify DAO tests block a second commit and allow recommit after deletion.
- [x] 9.6 Implement debt deletion with confirmation while keeping committed transactions; verify a widget/DAO test confirms the transaction survives.

## 10. Integration and release readiness

- [x] 10.1 Remove the Android `INTERNET` permission and verify with `aapt dump permissions` on a debug APK that no network permission remains.
- [x] 10.2 Run the full end-to-end manual flow on an emulator: first wallet → expense → transfer → subscription due and pay → debt commit → analytics; verify totals and balances stay consistent across an app restart.
- [x] 10.3 Run `fvm flutter analyze`, `fvm flutter test`, and `fvm flutter build apk --release --analyze-size`; verify no analyzer issues, all tests pass, and the Material Symbols size cost is documented.
- [x] 10.4 Add a `README.md` with FVM setup, `build_runner` command, test commands, and the offline/data model overview; verify the commands run as written on a clean checkout.
- [x] 10.5 Walk every acceptance scenario in the seven spec files and record any mismatch as a follow-up task; verify each scenario is either passing or explicitly listed.
- [x] 10.6 Run the UX pass at 360×640 dp and 200% text scale: add an expense one-handed, check for clipped labels, verify inline errors, snackbars, and the pinned save bar, and record each issue as a follow-up task.

## Workflow follow-up

- Review the implemented change against the specs, then archive it with `openspec archive add-money-management-app`.
- Sync the capability specs into `openspec/specs/` during archive and verify `openspec validate --all --strict` passes afterward.
