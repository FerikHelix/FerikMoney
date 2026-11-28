# app-foundation Specification

## Purpose

Provides local storage, the app shell, Material 3 presentation, interaction and copy rules, and shared formatting for every FerikMoney feature.

## Requirements

### Requirement: Offline operation

The app SHALL start and remain fully usable without a network connection or user account. No feature SHALL require a remote service.

#### Scenario: First launch without network
- **WHEN** a user launches the app for the first time with no connectivity
- **THEN** the app opens normally and every money feature is available

#### Scenario: No account required
- **WHEN** the app starts for the first time
- **THEN** the user is not asked to sign in, register, or provide an email address

### Requirement: Durable local data

Every committed change SHALL persist in local storage and survive app restarts or unexpected termination. Money-affecting changes SHALL be applied atomically, so a failure never leaves balances and entries inconsistent.

#### Scenario: Data survives restart
- **WHEN** a user records an expense and then force-closes and reopens the app
- **THEN** the expense and the updated wallet balance are still present

#### Scenario: Interrupted write
- **WHEN** the app is terminated while a transaction is being saved
- **THEN** after reopening, the transaction is either fully present or fully absent, and balances match the stored entries

### Requirement: Material 3 presentation

All screens SHALL use Material 3 components, color roles, and Material Symbols icons. Primary actions SHALL use filled buttons, destructive actions SHALL use the error color with an explicit verb, and the app SHALL support light, dark, and system theme modes.

#### Scenario: Dark mode
- **WHEN** the user selects dark mode
- **THEN** every screen, sheet, and dialog adopts the dark Material 3 color scheme without unreadable text

#### Scenario: Icon consistency
- **WHEN** a screen presents an action, wallet type, or category
- **THEN** it uses a Material Symbols icon that matches the meaning of that item

#### Scenario: Primary action
- **WHEN** a form can be saved
- **THEN** its save button is a filled button with a verb label and remains visible above the keyboard

### Requirement: Top-level navigation

The app SHALL provide five top-level destinations — Beranda, Kantong, Analitik, Langganan, and Utang — and SHALL preserve each destination's state when the user switches between them.

#### Scenario: Switch destinations
- **WHEN** the user selects another destination from the navigation bar
- **THEN** that destination opens at its previous scroll position and filter state

#### Scenario: System back
- **WHEN** the user presses the system back button on a top-level destination
- **THEN** the app returns to Beranda before exiting

### Requirement: Theme preference persistence

The selected theme mode SHALL persist across restarts and SHALL default to following the system setting.

#### Scenario: Restart keeps theme
- **WHEN** the user selects light mode and later reopens the app
- **THEN** the app starts in light mode

### Requirement: Rupiah formatting

Monetary values SHALL be displayed as whole Indonesian rupiah using Indonesian grouping and an `Rp` prefix, without decimal places.

#### Scenario: Grouped amount
- **WHEN** the value 1234567 is displayed
- **THEN** it appears as `Rp 1.234.567`

#### Scenario: Negative amount
- **WHEN** a negative balance is displayed
- **THEN** it appears as `-Rp 1.234.567` and is visually marked as negative

### Requirement: Local calendar dates

Dates SHALL represent the calendar date the user selected in local time and SHALL NOT shift when the device time zone or daylight-saving rules change.

#### Scenario: Time zone change
- **WHEN** the user records a transaction dated 1 March and later changes the device time zone
- **THEN** the transaction still displays 1 March

### Requirement: Layout resilience

The app SHALL lay out forms and lists in a single column at 360 dp width, with 16 dp screen margins and touch targets of at least 48×48 dp. At 200% text scale, labels, values, and buttons SHALL NOT clip or overlap.

#### Scenario: Small phone
- **WHEN** the app renders on a 360 dp wide screen
- **THEN** every form field and primary action is visible without horizontal scrolling

#### Scenario: Large text
- **WHEN** the user sets text scale to 200%
- **THEN** wallet names and rupiah amounts wrap or ellipsize, and the full value remains available to accessibility services

### Requirement: Inline validation

Validation errors SHALL appear next to the affected field when the user leaves it or saves, SHALL state the cause and the fix, and SHALL NOT open a blocking dialog. The app SHALL keep entered data while the user corrects it.

#### Scenario: Invalid amount
- **WHEN** the user saves an expense with an empty amount
- **THEN** the message "Nominal harus lebih dari Rp 0" appears below the amount field and the form stays open

#### Scenario: Duplicate wallet name
- **WHEN** the user saves a wallet name that already exists
- **THEN** the name field shows the conflict and the other entered values remain

### Requirement: Save feedback

A successful save SHALL return to the previous screen and show a short snackbar naming the saved item. A failed save SHALL keep the form open with its data and show a recoverable error with a retry action.

#### Scenario: Saved expense
- **WHEN** an expense saves successfully
- **THEN** the app returns to the previous screen and shows a snackbar such as "Pengeluaran disimpan"

#### Scenario: Failed save
- **WHEN** the local write fails
- **THEN** the form stays open with its values and shows an error with a retry action

### Requirement: Plain interface copy

Interface copy SHALL be Indonesian, sentence case, and limited to the action or fact it communicates. Action labels SHALL start with a verb, errors SHALL state cause and fix, and the app SHALL NOT use exclamation marks, emoji, filler, or blame.

#### Scenario: Action label
- **WHEN** a form offers to save a new expense
- **THEN** the button reads "Simpan pengeluaran", not "OK" or "Simpan!"

#### Scenario: Empty state
- **WHEN** a list has no items
- **THEN** the state shows one factual sentence and one action, without cheerleading or apology

#### Scenario: Copy check
- **WHEN** the copy test scans the Indonesian ARB file
- **THEN** no value contains an exclamation mark or emoji

### Requirement: Confirmation scope

The app SHALL require confirmation only before destructive actions, discarding unsaved form changes, and balance overrides such as a negative balance. Routine creates and edits SHALL save without a confirmation dialog.

#### Scenario: Routine save
- **WHEN** the user saves a valid expense
- **THEN** no confirmation dialog appears

#### Scenario: Destructive action
- **WHEN** the user deletes a transaction
- **THEN** a confirmation dialog names the item and the delete action

#### Scenario: Unsaved changes
- **WHEN** the user leaves a form with entered values that were not saved
- **THEN** the app asks whether to discard them

### Requirement: Accessible semantics

Every icon-only control SHALL expose a semantic label. Screen readers SHALL announce amounts with their sign and context, along with statuses such as income, expense, overdue, and settled.

#### Scenario: Icon-only action
- **WHEN** a screen reader focuses the add action
- **THEN** it announces "Tambah pengeluaran"

#### Scenario: Balance announcement
- **WHEN** a screen reader focuses a negative wallet balance
- **THEN** it announces the negative amount and the wallet name

### Requirement: Schema migration

App updates SHALL preserve existing local data through versioned migrations. A destructive reset SHALL occur only after explicit user confirmation.

#### Scenario: Upgrade preserves data
- **WHEN** the user installs an app update that changes the local schema
- **THEN** all existing wallets, transactions, subscriptions, and debts remain available

#### Scenario: Failed migration
- **WHEN** a migration cannot complete
- **THEN** the app reports the problem and offers a confirmed reset instead of silently discarding data
