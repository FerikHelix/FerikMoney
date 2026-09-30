# FerikMoney — UX, Feature & User-Flow Audit

> Status: **audit only. No source code has been changed.** Implementation starts after review.
> Scope: the current working tree (V2: budgets, savings goals, recurring, reports, tags, currency), which is **uncommitted**.
> UI language is Indonesian; UI strings are quoted as they appear.

**How this was produced.** Three read-only passes over navigation/home/theme, feature screens/forms, and data/state/tests. The high-severity claims were then re-checked directly in code. Where a claim was corrected during verification it is noted. I did **not** run `flutter analyze` or `flutter test`, so the baseline pass/fail state is unknown.

**Verdict in one paragraph.** The foundations are good: the transaction form is fast, balances are derived correctly, backups are validated, and the theme has real tokens. The complexity comes from (a) *duplication* — the same destinations and the same information appear in 2–5 places; (b) *Home trying to be Reports*; (c) *secondary features (budgets, goals, recurring) that are half-finished* — no delete, no unarchive, no confirmation, no feedback; and (d) *inconsistent patterns* across sheets, snackbars, headers and terminology. Most fixes are **removal, relocation or wiring up things the data layer already supports**, not new features.

---

## 1. Current App Structure

### Navigation
- `GetMaterialApp(home: MainShell())`. **No route table** (`lib/app/routes/` is empty); every push is an imperative `Get.to(...)`.
- `MainShell` = `IndexedStack` of **Home · Transaksi · Laporan · Lainnya** (all four kept alive), Material 3 `NavigationBar`, and **one global centered FAB** ("Catat Transaksi"). With no accounts the FAB shows a snackbar instead of opening the form.
- Pushed pages (Accounts, Account detail, Budgets, Savings, Recurring, Categories, Settings) cover the shell, so nav bar and global FAB disappear; **each brings its own FAB** (plain in Accounts/Categories, extended "Tambah" in Budgets/Savings/Recurring).
- Forms and details are bottom sheets. Dialogs are used for confirmations only.
- Tab index is switched from outside the shell in exactly one place: `home_view.dart:191` (`navigationIndex.value = 1`, a hard-coded tab number).

### Where each thing lives today
| Destination | Entry points | Taps |
|---|---|---|
| Add transaction | Global FAB; Home "Tambah Cepat" chips; Home "Form lengkap"; Home empty-state button; History empty-state button | 1 |
| Settings | Home gear icon; Lainnya → Pengaturan | 1 / 2 |
| Categories | Lainnya → Kategori; Settings → Data → "Kelola Kategori" | 2 / 3 |
| Accounts list | Home "Akun Saya › Lihat semua"; Lainnya → Wallet | 1 / 2 |
| Account detail | Home account card; Accounts list row | 1 / 2 |
| Budget / Target Tabungan / Transaksi Berulang | Lainnya only | 2 |
| Reports | Tab 3 | 1 |
| Backup / CSV / Import / Reset / Currency / Theme | Settings | 2–3 |

### Architecture (must stay intact while refactoring UI)
- **State:** GetX (`GetxController` + `.obs`, `Obx`, `Get.find`). Drift `watch*` streams feed controllers. Singletons registered in `main()` (Theme/Privacy/AppPreferences/Currency services) and `InitialBinding` (DB, 5 repositories, `BackupService`, Money/Budget/Recurring/Savings/Reports controllers).
- **Cross-controller coupling:** `MoneyController.totalBalance/activities` → `SavingsController`; `BudgetController` → `MoneyController`; `ReportsController` → `MoneyController` + `AppPreferencesService`; `RecurringController.onInit` runs `generateDue()`.
- **DB:** Drift/SQLite, `schemaVersion = 2`, UUID text ids, integer minor units. **Balances are never stored** — computed in SQL from `initialBalance` ± transactions ± goal deposits/withdrawals. Total money = wallet balances **+ goal savings**.
- **Backup:** JSON envelope `version` 1|2, strict validation, atomic restore; CSV export; reset re-seeds 17 stable-id default categories. Renaming any JSON key/column breaks old backups.
- **Theme:** `FerikColors` `ThemeExtension` (light + dark palettes), `AppSpacing` (4/8/12/16/20/24/32), `AppRadius` (12/16/20/24/28), Material 3.
- **Dead code:** `features/statistics/statistics_view.dart` (373 lines) is referenced by nothing (verified). Overlaps `ReportsView`.
- **Unused dependency:** `cupertino_icons`.

---

## 2. Problems Found

Severity: **High** = breaks or blocks a task / loses trust; **Medium** = clear friction or duplication; **Low** = polish/consistency. "✔ verified" = re-checked in code during this audit.

### High
| # | Screen | Current behavior | Why it hurts | Proposed solution |
|---|---|---|---|---|
| H1 | Transaction delete | Row → detail sheet → "Hapus Transaksi" → `AlertDialog` → "Hapus" (3 taps). Then a **5 s UNDO snackbar** appears. ✔ `transaction_detail_sheet.dart:32-76` | Confirmation *and* Undo are redundant; slows a rare-but-important task while adding no safety. Undo snackbar shows at the **top** (no `snackPosition`). | Keep Undo, drop the dialog (see §5). Show the snackbar at the bottom, above the FAB. |
| H2 | Home / History | Savings-goal deposits/withdrawals appear as rows but have **no `onTap`**. ✔ `finance_activity_tile.dart:48-109` | A wrong goal transfer cannot be found-and-fixed from where the user sees it. | Make the row tappable → small sheet (amount, wallet, note, delete). Reuse the `_showTransfer` sheet. |
| H3 | Budgets | Tap opens edit; **no delete, no archive**. ✔ Repo has `BudgetRepository.delete` (`budget_repository.dart:81`) but no UI calls it. `budgets.isActive` is never toggled either. | A wrongly-created budget is permanent. | Add "Hapus budget" in the edit sheet (with confirm). Pure UI wiring, no schema change. |
| H4 | Accounts | Only archive; **no delete**. ✔ `MoneyRepository.deleteAccount` exists (`money_repository.dart:113`) and correctly refuses when transactions reference the account, but no UI calls it. | A typo'd or accidental empty wallet can only be archived, cluttering the archive forever. | Offer "Hapus" in Account detail only when the account has no transactions; otherwise show "Arsipkan". |
| H5 | Savings goals | "Arsipkan" in the overflow menu: **no confirmation, no snackbar, no way back**; archived goals are filtered out and unreachable. ✔ `savings_goals_view.dart:249, 291-309` | Data seems to vanish. | Add a "Diarsipkan" section (mirrors Accounts/Categories) with unarchive, plus an archive snackbar with Undo. |
| H6 | Recurring | Overflow "Hapus" deletes the rule **immediately**. ✔ `recurring_view.dart:367`. "Lewati" on a pending occurrence also acts instantly with no undo. ✔ `:432` | Destroys a schedule with one mis-tap next to Edit. | Confirm on delete; snackbar with Undo on skip. |
| H7 | History filtering | Search is good, but a date filter takes ~8 taps (tune → dropdowns → range picker → Terapkan). No month navigator, no presets, no jump-to-date; long history = long scroll. | "Find an old transaction" is a core flow. | Month chip strip / prev-next month header + quick presets ("Bulan ini", "Bulan lalu", "7 hari") on the History screen itself; keep the sheet for advanced filters. |
| H8 | Reports | Category rows/donut are **not tappable**; totals can't be cross-checked with the transaction list. No % per category. Week label shows only the start date. | The monthly review is a dead end; the user asks "what's in Makanan?" and has no answer. | Tap category → History pre-filtered (type, category, date range). Show % beside amounts. |
| H9 | Forms: Budget, Goal, Goal-transfer, Category, Recurring | Plain `Column(mainAxisSize.min)` without scroll view (Category sheet also lacks `useSafeArea`); **no `_saving` guard**; Budget/Goal/Recurring don't catch generic exceptions. ✔ `categories_view.dart:21` (no `useSafeArea`, no `SingleChildScrollView`) | Keyboard can overflow the sheet on small phones; double-tap can submit twice; unexpected errors are silent. | One shared keyboard-safe sheet scaffold with scroll, safe-area and a `saving` flag. |
| H10 | Home vs Accounts | Hero "Total Uang" = wallets **+ goal savings**; account cards show wallets only. | The accounts → balances relationship the user explicitly cares about doesn't add up on one screen. | Label the hero clearly ("Total uang" with a subtle "termasuk tabungan Rp X" line) or show "Saldo wallet" and "Tabungan" as two lines. |

### Medium
| # | Screen | Current behavior | Why it hurts | Proposed solution |
|---|---|---|---|---|
| M1 | Home | Period selector (Minggu/Bulan/Tahun) + income/expense metrics + "Pengeluaran terbesar" card duplicate Reports; selector state is local and **unrelated** to Reports' own period. | Two sources of "this month" that can disagree; extra controls on the most important screen. | Home shows *this month* only (no selector). Tapping the metrics opens Reports. Remove the top-category card (Reports owns it). |
| M2 | Home | `_BudgetSummary` and `_SpendingSummary` are cards that look tappable but do nothing. | Dead affordances. | Make the budget strip open Budgets; delete the spending card (see M1). |
| M3 | Home | Five ways to open the transaction form (FAB, chips, "Form lengkap", Home empty-state button, History empty-state button). | Noise; "Form lengkap" is redundant with the FAB. | Keep FAB + category chips. Remove "Form lengkap". Keep one contextual empty-state CTA. |
| M4 | Settings / Categories | Categories reachable from Lainnya **and** Settings → Data. Settings reachable from Home gear **and** Lainnya. | Duplicate paths for rarely-used screens. | Keep Lainnya as the one hub; remove both duplicates. (Home gear can go; privacy eye stays.) |
| M5 | Accounts | Reachable from Home ("Lihat semua"), Lainnya → Wallet, and Home cards. The list page repeats "Total Uang" with an eye toggle (already on Home). | Same total on three screens. | Keep Home strip + Lainnya; drop the duplicate total card on the Accounts page (or reduce to a subtitle). |
| M6 | Transaction form | Save button is disabled with **no reason shown** when the amount is empty. | User doesn't know what's missing. | Helper text/inline hint ("Isi nominal") or enable-and-validate. |
| M7 | Transaction edit | Detail sheet → Edit closes the sheet and opens the form via `Get.context!`; category picker opens a *third* sheet on top. | 3-deep sheet stack; fragile context usage. | Edit directly from the detail sheet's context; use inline chip lists / a single picker step. |
| M8 | Transaction form | Date: "Tanggal" row + "Hari ini"/"Kemarin" chips + separate "Waktu" row. | Three controls for one concept. | One "Tanggal" row: chips Today/Yesterday/Pilih tanggal; time stays inside "Detail lainnya". |
| M9 | Recurring form | 8 fields visible (Nama, type, amount, wallet, category/dest, frequency, start date, note). | Only amount/wallet/category/name are needed; the rest have safe defaults. | Move frequency, start date and note behind "Detail lainnya" (same pattern as the transaction form). |
| M10 | Rows: Goals & Recurring | Card tap opens Edit **and** the overflow menu also has Edit. | Duplicate action. | Keep card tap = edit; overflow keeps only destructive/status actions (Arsipkan / Hapus / Jeda). |
| M11 | Privacy flag | `MoneyText` in Budgets and Goals doesn't pass `visible:`; Recurring hard-codes `visible: true`. | The "hide amounts" toggle leaks numbers on three screens. | Make `MoneyText` read `PrivacyService` by default. |
| M12 | Categories | No empty state per section (✔ no `EmptyState` in `categories_view.dart`); the archive icon sits at the far right beside the tappable row. | Mis-taps and blank sections. *(Corrected: archive **is** reversible via the "Diarsipkan" section and shows a snackbar — so this is not a data-loss risk.)* | Add empty states; move archive into the edit sheet or use swipe. |
| M13 | First launch | Welcome state shows an `AppBar`, "Belum ada akun", and a "Tambah Akun" button while the global FAB and bottom nav stay active (FAB then shows a snackbar). No hint that a wallet is required first. | The most important screen is the least guided. | Welcome copy explains "Mulai dengan menambahkan dompet"; hide FAB; prefill account name "Tunai" so first save = 2 taps. |
| M14 | Snackbars | 39 snackbar call sites; only **6** set `SnackPosition.BOTTOM` (✔). The rest appear at the top; bottom ones can hide behind the FAB. Titles are inconsistent ("Periksa transaksi", "Tidak dapat menyimpan", …). | Feedback jumps around the screen. | One `showFeedback(...)` helper: bottom, above FAB, consistent tone. |
| M15 | Accounts form | "Saldo Awal" isn't explained; type labels differ between form ("Dompet digital"), list ("E-wallet") and Home (`_accountTypeLabel` lacks `savings`, so savings accounts read "Tunai"). ✔ per exploration | Confusing accounts → balance relationship. | One shared label map; add helper text "Saldo saat mulai memakai FerikMoney". |
| M16 | Settings | Three selector patterns in one card (SimpleDialog radio for currency, inline dropdowns, segmented button); restore/export show no progress; reset needs one tap-confirm with no backup nudge. | Inconsistent; destructive action under-protected. | Unify to a single row-with-sheet pattern; add progress on backup/restore; reset dialog offers "Backup dulu". |
| M17 | Budgets | Month fixed to `DateTime.now()`; overall vs category scope is a dropdown; amount is a plain `TextField` (not `AmountInput`). | Inconsistent input; no way to see last month. | Use `AmountInput`. (Month history → "worth documenting", not built.) |

### Low
| # | Item | Fix |
|---|---|---|
| L1 | Terminology drift: "Wallet" / "Akun" / "Akun Saya"; "Kategori" / "Kelola Kategori"; tab "Transaksi" vs heading "Riwayat"; tab "Home" is English among Indonesian labels; "E-wallet" vs "Dompet digital". | Pick one glossary (proposal: **Dompet** for accounts, **Kategori**, **Transaksi**, **Beranda**). |
| L2 | Hard-coded values: amber `Color(0xFFD49A3A)` in `home_view.dart:249` and `budgets_view.dart:148`; radii `7`/`8`; spacing `10`/`16`; `fontSize: 32` in `amount_input.dart`. | Add `warning` token; use `AppRadius`/`AppSpacing`. |
| L3 | Light/dark branching leaks into widgets (`context.isFerikDark ? … : …` in `ferik_card`, `main_shell`, `account_card`, `transaction_tile`, `history_view`); several theme component entries are null in dark mode. | Move to tokens/`ThemeData` so both themes use the same code path. |
| L4 | `FerikCard` re-implements `cardTheme` (own `Material`, elevation 1, shadow). | Have it read the theme; single source. |
| L5 | Section headers: `SectionHeader` (Home/Accounts/Categories), `_SectionLabel` (Settings), raw `titleLarge` (Reports/Recurring). Tab headings hand-rolled in Lainnya/Laporan/Riwayat. | Reuse `SectionHeader`; add a tiny `PageHeader`. |
| L6 | Tap targets below 48 dp: `SectionHeader` action (44×40), `ActionChip`/`ChoiceChip` (32 dp), Reports prev/next (40 dp), type selector segments (44 dp). | Raise to ≥48 dp (`materialTapTargetSize`, padding). |
| L7 | Bottom padding inconsistent (100 vs `AppSpacing.xxl`); export sheets differ in padding; category icon picker is a text-only dropdown. | Standardize; show icon previews. |
| L8 | Reports: future navigation unbounded; no whole-page empty state; period change resets anchor. | Clamp "next" to current period; page-level empty state. |
| L9 | `Get.snackbar('Dipulihkan', …)` and other feedback after goal/recurring/budget saves is missing. | Covered by the feedback helper (M14). |
| L10 | `Home` empty-state "Catat Transaksi" doesn't check for accounts (History's does). | Share one guard. |
| L11 | Dead `StatisticsView`; unused `cupertino_icons`. | Delete / remove. |

---

## 3. Feature Classification

**Core** *(must be one tap away, never cluttered)*
- Add expense / income (FAB + form with remembered account/category)
- Home: total balance, this month's income/expense, recent activity
- Transaksi (History): search, day-grouped list, detail, edit/delete/duplicate
- Accounts (wallets) and basic Categories

**Secondary** *(useful, not daily; keep reachable, not prominent)*
- Reports (monthly review) — deserves its tab because monthly review is a stated core flow
- Budgets (overall + per-category)
- Savings goals
- Recurring transactions (+ pending-confirmation queue)
- Transfers between wallets, Tags, advanced History filters

**Advanced / Settings**
- Backup JSON, CSV export, Import/Restore, Reset
- Currency, first weekday, default wallet, theme, hide-amounts

**Questionable** *(not deleted automatically; see recommendation)*
| Feature | Problem | Recommendation |
|---|---|---|
| Home period selector + top-category card | Duplicates Reports; disconnected state. | **Remove** from Home (Reports owns period analysis). |
| Home "Form lengkap" | Redundant with FAB. | **Remove.** |
| Home gear → Settings / Settings → Kelola Kategori | Duplicate entry points. | **Remove** both; Lainnya is the hub. |
| `StatisticsView` | Dead, overlaps Reports. | **Delete.** |
| Goal savings inside "Total Uang" | Correct math, confusing presentation. | **Keep, but label** (H10). |
| Tags | Heavy for a low-frequency feature. | **Keep**, already behind "Detail lainnya". Don't promote. |
| Budgets `isActive` column | Written, never surfaced. | **Leave alone** (no schema change); don't build UI for it. |

---

## 4. Navigation Proposal

### Current
```
[Home] [Transaksi] [Laporan] [Lainnya]     (+ global FAB)
Home ──► Settings (gear), Accounts (Lihat semua), History (Semua), Add (chips / Form lengkap)
Lainnya ─► Wallet · Budget · Target Tabungan · Transaksi Berulang · Kategori · Pengaturan
Settings ─► Kelola Kategori (duplicate)
Pushed pages ─► own FABs, no bottom nav
```

### Recommended (4 tabs kept — least disruptive, matches the existing smoke test)
```
[Beranda] [Transaksi] [Laporan] [Lainnya]  (+ global FAB, hidden on the welcome state)

Beranda  : balance hero · hari ini/bulan ini · dompet strip · quick-add chips · recent activity
Transaksi: search · month navigator + presets · list      (filters sheet = advanced only)
Laporan  : period summary · trend · categories (tap → Transaksi filtered)
Lainnya  : Dompet · Kategori · Budget · Target Tabungan · Transaksi Berulang (badge) · Pengaturan
```
**Why keep four tabs.** Home / History / Reports each map to a frequent verb (*glance, find, review*). Budgets, goals and recurring are "set up once, glance occasionally" and belong one level down. Moving Reports into History would make History overloaded and force a bigger refactor for little gain.

**Concrete changes**
1. Remove duplicate entry points: Home gear, Settings → Kategori, Home "Form lengkap".
2. Replace `navigationIndex.value = 1` with a named constant/enum so tab order can change safely.
3. Pushed secondary pages: drop their own FABs in favour of a single in-page "Tambah" action in the app bar or an empty-state CTA (keeps the "one FAB = add transaction" mental model).
4. Home welcome state: no FAB, explanatory copy.
5. Tab label "Home" → "Beranda" (**requires updating `v2_app_smoke_test.dart` in the same change**).
6. Deep-link from Home budget strip → Budgets, from Home metrics → Laporan, from Reports category → Transaksi (filtered).

---

## 5. Flow Improvements

| Flow | Current | Recommended |
|---|---|---|
| **First launch** | Welcome → "Tambah Akun" → name → (type) → (balance) → Simpan (4+ taps, empty form) | Welcome (explains wallet) → "Tambah Dompet" → name prefilled "Tunai" → Simpan (**2 taps**) |
| **Add expense** | FAB → type amount → Simpan (2 taps) ✔ already good | Same. Add a visible reason when Save is disabled; keep chips & remembered defaults. |
| **Add income** | FAB → Masuk → amount → Simpan (3 taps) | Same (the extra tap is inherent). |
| **Today's spending** | Home hero shows month-level numbers; scroll to recent list | Add a compact "Hari ini: −Rp X" line in the hero; recent list already right below. |
| **Find old transaction** | Transaksi → tune → dropdowns → range picker → Terapkan → scroll (~8) | Transaksi → month header ◄ ► or preset chip → (search) (**2–3**). Advanced sheet only for account/category/type. |
| **Edit transaction** | Row → detail → Edit → (close sheet, reopen form) | Row → detail → Edit (form opens from the same route; no `Get.context!`). |
| **Delete transaction** | Row → detail → Hapus → dialog → Hapus → snackbar UNDO (3) | Row → detail → Hapus → snackbar UNDO (**2**). Undo is the safety net; the dialog is the redundant one. |
| **Fix a goal transfer** | Impossible from History/Home | Tap row → sheet with edit/delete |
| **Monthly review** | Laporan → ◄ ► → read; no drill-down | Laporan → tap a category → Transaksi filtered to that category & range |
| **Manage accounts** | Lainnya → Wallet → detail → Edit/Archive; no delete | Same path; add Delete for empty accounts; unified type labels; helper text on opening balance |
| **Budget** | Lainnya → Budget → Tambah → scope dropdown + amount | Same; add Hapus; `AmountInput`; Home strip becomes the entry point |
| **Goal deposit** | Lainnya → Target → card → amount → Simpan | Same; add success feedback, default wallet = user's default wallet; archived section |
| **Recurring** | Lainnya → Berulang → Tambah → 8 fields | Tambah → 4 fields + "Detail lainnya"; confirm delete; undo skip |

---

## 6. UI Simplification Opportunities

| Screen | Remove | Combine | Move / hide | Redesign |
|---|---|---|---|---|
| **Home** | Period selector; "Pengeluaran terbesar" card; "Form lengkap"; gear icon | Income/expense metrics + "Hari ini" into the hero | Budget strip → one tappable line (only if a budget exists) | Hierarchy: **balance → this month in/out → dompet → quick add → recent**. Hide dompet strip's "Lihat semua" (Lainnya has it). |
| **Transaksi** | Sort from the filter badge count | — | Advanced filters stay in the sheet | Month navigator + presets on top; "Hapus N filter" chip → bigger target |
| **Laporan** | Duplicate empty zero cards | Summary + insight into one block | Income-by-category collapsed | Tappable rows with %, clamp future navigation |
| **Lainnya** | — | Wallet/Kategori under "Kelola"; Budget/Target/Berulang under "Perencanaan"; Pengaturan last | — | Two small labelled groups instead of one flat card + lone Settings card |
| **Accounts** | Duplicate "Total Uang" card | — | Archived stays collapsed | Type chips in the form |
| **Recurring form** | — | — | Frequency, start date, note → "Detail lainnya" | Selector rows (like the transaction form) instead of dropdowns |
| **Settings** | Kelola Kategori link | Backup/Export/Import into one "Data" row group | Reset behind an "Zona berbahaya" subsection | Single selector pattern |
| **Transaction form** | Separate Waktu row | Date chips + row into one | Time → "Detail lainnya" | Inline "why disabled" hint |

---

## 7. Features Worth Keeping (don't touch without cause)

- **Transaction form defaults** — autofocused amount, last-used account/category, "Sering digunakan" chips, and the "Detail lainnya" panel (auto-expands when a note/tags exist). This is the best flow in the app.
- **Delete-with-UNDO** snackbar (`restoreTransaction` re-inserts with tags).
- **Computed balances** from SQL; **atomic, validated restore**; stable default-category ids.
- **Privacy eye toggle** and `MoneyText` semantics.
- **Recurring "Review & Buat"** reusing the transaction form via `initialValue`.
- **Day-grouped History** with per-day net and "HARI INI / KEMARIN" labels.
- **Theme tokens** (`FerikColors`, `AppSpacing`, `AppRadius`) — real foundation; extend, don't replace.
- **Currency lock** after data exists (prevents corrupting amounts).
- **Recurring badge** on the Lainnya tile (pending items).

## 8. Features Worth Reworking

| Feature | What's wrong | Direction |
|---|---|---|
| Home dashboard | Doing Reports' job; dead cards; unclear total | §6 Home column |
| History filtering | Too many steps for date | Month navigator + presets |
| Reports | Dead end | Drill-down + % |
| Budgets | No delete; fixed month; plain input | Delete, `AmountInput` |
| Savings goals | No unarchive/feedback | Archived section, snackbars |
| Recurring | Long form; duplicate edit; unsafe delete/skip | Disclosure + confirm/undo |
| Categories | No empty state; risky icon placement | Empty states; archive in sheet |
| Settings | Three selector patterns; no progress; thin reset protection | Unify; progress; backup nudge |
| Feedback/errors | 39 snackbars, mixed position/tone | Single helper |
| Sheets | 3 different scaffolds, some can overflow | One scaffold (scroll, safe area, saving flag) |

## 9. Features Potentially Worth Removing

Only where there's a strong UX case — and all are UI-only removals with no data impact:
1. `StatisticsView` (dead code, 373 lines).
2. Home period selector and "Pengeluaran terbesar" card (duplicates Reports).
3. Home "Form lengkap" (duplicate of FAB).
4. Settings → "Kelola Kategori" link and Home settings gear (duplicate paths).
5. Unused dependency `cupertino_icons`.

Nothing else is proposed for removal. In particular, **budgets, goals, recurring, tags and reports are kept** — they're powerful and correctly hidden one level down; they need finishing, not deleting.

## 10. Valuable but Missing (documented, **not** to be built now)
- Month-by-month budget history (budget view is "now" only).
- "Delete all data for an account" / merge accounts.
- Per-period CSV export from Reports.
- First-run 3-step coach marks (only worth it if the welcome-state copy proves insufficient).
- Category icon picker with previews (beyond a minimal fix).

---

## 11. Proposed Implementation Plan (after your review)

Incremental, one phase at a time; analyze + tests after each phase. **No schema change (`schemaVersion` stays 2); backup JSON keys unchanged; no new packages.**

**Phase 1 — Flow**
- Remove duplicate entry points (Home gear, Settings→Kategori, "Form lengkap"); named tab constants.
- Welcome state: FAB hidden, explanatory copy, prefilled "Tunai".
- Delete flow (drop redundant dialog, Undo at bottom); goal-transfer rows tappable.
- History month navigator + presets; Reports category drill-down.
- Wire existing repository methods: budget delete, empty-account delete, goal unarchive.

**Phase 2 — Simplification**
- Trim Home (period selector, spending card, Form lengkap); tappable budget strip; "Hari ini" line.
- Recurring form disclosure; single date control in transaction form; remove duplicate Edit actions.
- Delete `StatisticsView`, drop `cupertino_icons`.

**Phase 3 — Hierarchy**
- Home hierarchy pass (balance first, breakdown of wallet vs. savings), Lainnya grouping, spacing/typography.

**Phase 4 — Consistency**
- Shared `PageHeader`, keyboard-safe sheet scaffold (scroll + safe area + `saving`), `showFeedback` helper, `warning` token, glossary pass, privacy default in `MoneyText`, tap targets ≥ 48 dp, move dark/light branching into tokens.

**Phase 5 — Polish**
- Empty states (Categories, Reports), loading state, Settings progress and reset nudge, subtle transitions.

### Regression guardrails
Tests that must stay green (and what they pin):
- `test/widgets/v2_app_smoke_test.dart`: texts `Total Uang` (exactly one), `Aktivitas Terbaru`, `Cari transaksi`, `Pengeluaran per Kategori`; tab labels `Transaksi` and `Laporan` tappable and unique; FAB tooltip `Catat Transaksi`; keys `transaction-save-button`, `expense-donut-painter`, `transaction-type-*`; controllers must resolve without `ThemeService`/`BackupService`. **Renaming "Home" → "Beranda" requires updating this test in the same change.**
- `test/widgets/v2_components_test.dart`: exact expense fill colors, `−Rp 125.750.000`, no overflow at 320–480 px @1.3× text.
- `test/app_theme_test.dart`: palette values — token refactors must keep values.
- DB/backup/migration/currency tests: untouched by UI work.

### Risks
- **The V2 work is uncommitted** — 26 modified + many untracked files, and only one commit exists (V1). Recommend **committing the current tree first** so each phase has a clean baseline and is easy to review/revert. (I won't commit for you.)
- Baseline `flutter analyze` / `flutter test` status is unknown; run both before Phase 1.
- Hard-coded `find.text('Transaksi')` in the smoke test means any additional widget with that exact text will break tapping — mind duplicates when adding month headers.
