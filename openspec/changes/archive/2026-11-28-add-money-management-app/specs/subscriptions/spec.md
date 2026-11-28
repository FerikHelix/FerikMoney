# Spec Delta

## Purpose

Tracks recurring subscriptions, reminds the user in-app when one is due, and records payment only after the user confirms.

## ADDED Requirements

### Requirement: Create a subscription

Users SHALL be able to create a subscription with a name, whole-rupiah amount, active wallet, expense category, cycle (monthly or yearly), due day, reminder lead time, and optional note.

#### Scenario: Monthly subscription
- **WHEN** the user saves "Netflix", Rp 54.000, monthly, due on day 15, billed to wallet "BCA"
- **THEN** the subscription appears in the subscription list with its next due date

#### Scenario: Invalid due day
- **WHEN** the user enters a due day outside 1–31
- **THEN** the app blocks saving and identifies the valid range

### Requirement: Due date calculation

Monthly subscriptions SHALL fall due on the chosen day of each month, clamped to the last day when the month is shorter. Yearly subscriptions SHALL fall due on the chosen month and day, clamping 29 February to 28 February in non-leap years.

#### Scenario: Day 31 in February
- **WHEN** a monthly subscription is due on day 31
- **THEN** in February it falls due on the last day of February

#### Scenario: Leap day
- **WHEN** a yearly subscription is due on 29 February and the year is not a leap year
- **THEN** it falls due on 28 February

### Requirement: Home reminder banner

Beranda SHALL show a reminder banner when an active subscription is due within its lead time or overdue and not dismissed for the current session. The banner SHALL show the number of due items and the nearest one, and SHALL open the subscription list when tapped.

#### Scenario: One due subscription
- **WHEN** a subscription is due in two days with a three-day lead time
- **THEN** Beranda shows a banner naming that subscription and its amount

#### Scenario: No due subscriptions
- **WHEN** no active subscription is inside its reminder window
- **THEN** Beranda shows no subscription banner

### Requirement: Dismiss a reminder

Users SHALL be able to dismiss a due reminder until the next app launch. Dismissing SHALL NOT mark the subscription paid or change its due date.

#### Scenario: Dismiss banner
- **WHEN** the user dismisses the banner and stays in the app
- **THEN** the banner stays hidden; after the app is reopened, the reminder returns while still due

### Requirement: Pay a subscription

Paying a subscription SHALL open a prefilled expense form with the subscription's amount, wallet, category, and today's date. The expense SHALL be created only when the user confirms saving, and the subscription SHALL advance one cycle only after that save succeeds.

#### Scenario: Confirm payment
- **WHEN** the user taps pay on a due subscription and saves the prefilled expense
- **THEN** an expense is recorded and the subscription's next due date moves one cycle ahead from the paid due date

#### Scenario: Cancel payment
- **WHEN** the user cancels the prefilled expense form
- **THEN** no expense is created and the subscription remains due

#### Scenario: Adjust before paying
- **WHEN** the user changes the prefilled amount before saving
- **THEN** the saved expense uses the adjusted amount while the subscription amount stays unchanged

### Requirement: Skip a cycle

Users SHALL be able to skip the current cycle after confirmation. Skipping SHALL advance the due date one cycle without creating any transaction.

#### Scenario: Skip this month
- **WHEN** the user confirms skipping a monthly subscription due today
- **THEN** the next due date moves to the same day next month and no expense is recorded

### Requirement: Edit or deactivate a subscription

Editing a subscription SHALL affect only future reminders and SHALL NOT change existing transactions. Deactivating SHALL stop reminders while keeping the subscription in the list.

#### Scenario: Change amount
- **WHEN** the user changes a subscription amount
- **THEN** past expenses remain unchanged and the next payment prefills the new amount

#### Scenario: Deactivate
- **WHEN** the user deactivates a due subscription
- **THEN** it stops appearing in the Beranda banner and remains listed as inactive

### Requirement: In-app reminders only

Version 1 SHALL surface subscription reminders only while the app is open and SHALL NOT schedule operating-system notifications.

#### Scenario: App closed on due date
- **WHEN** a subscription falls due while the app is closed
- **THEN** no system notification is sent; the banner appears the next time the app is opened
