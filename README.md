# FerikMoney

Offline-first personal money app for Android. It records income, expenses, and transfers across wallets ("kantong"), summarizes spending, and tracks subscriptions and utang/piutang without an account, backend, or network.

- Flutter 3.50.1 (pinned with FVM)
- Android only
- Indonesian rupiah (IDR), integer amounts
- Local SQLite via Drift
- Material 3 with Material Symbols

## Contents

- [Features](#features)
- [Stack](#stack)
- [Requirements](#requirements)
- [Local setup](#local-setup)
- [Run](#run)
- [Commands](#commands)
- [Project layout](#project-layout)
- [Data and balances](#data-and-balances)
- [CI and releases](#ci-and-releases)
- [Offline behavior](#offline-behavior)
- [Troubleshooting](#troubleshooting)

## Features

- **Kantong**: cash, bank, e-wallet, and other wallets with opening balance, icon, color, archive, and derived balances.
- **Transactions**: income and expenses with wallet, category, date, and note. Transfers support an optional fee.
- **Dashboard**: total balance, per-wallet cards, current-month income/expense/net, recent activity, and quick expense entry.
- **Analytics**: month picker, wallet filter, category breakdown with amounts and percentages, and a six-month trend.
- **Langganan**: monthly or yearly subscriptions, due reminders on Beranda, one-tap prefilled payment, skip cycle, and deactivate.
- **Utang/piutang**: a separate ledger with partial payments. Balances change only when a ledger entry is explicitly committed to a wallet.
- **Offline by default**: no login, no cloud sync, no telemetry, no `INTERNET` permission.

## Stack

| Area | Choice |
| --- | --- |
| UI | Material 3, Material Symbols Rounded |
| State | Riverpod |
| Navigation | go_router (`StatefulShellRoute`) |
| Storage | Drift + SQLite |
| Localization | `flutter_localizations`, ARB (`id`) |
| Dates/numbers | `intl`, `id_ID` |

## Requirements

- FVM 4.1 or newer
- Android SDK with an emulator or device
- JDK 17 or newer; CI uses Temurin 21
- Git

## Local setup

```powershell
fvm install 3.50.1
fvm use 3.50.1
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
```

`.fvmrc` pins Flutter 3.50.1. Drift generated files are committed, so `build_runner` is only required after changing tables or DAOs.

## Run

```powershell
fvm flutter run
```

The debug and profile manifests intentionally declare no `INTERNET` permission. Flutter's VM service and hot reload need it, so add it temporarily to `android/app/src/debug/AndroidManifest.xml` while debugging:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Remove it again before committing. The release build never declares it.

Device smoke test without the Flutter tool:

```powershell
fvm flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.ferik.ferik_money/.MainActivity
```

Package: `com.ferik.ferik_money`.

## Commands

| Command | Purpose |
| --- | --- |
| `fvm flutter analyze` | Static analysis |
| `fvm flutter test` | Unit, DAO, widget, copy, and layout tests |
| `fvm flutter test test/db` | Database and balance tests only |
| `fvm dart run build_runner build` | Regenerate Drift code |
| `fvm flutter gen-l10n` | Regenerate localizations from `lib/l10n/app_id.arb` |
| `fvm flutter build apk --debug` | Debug APK |
| `fvm flutter build apk --release` | Universal release APK |
| `fvm flutter build apk --release --split-per-abi` | Smaller per-ABI APKs |
| `fvm flutter build appbundle --release` | Play Store AAB |
| `fvm flutter build apk --release --target-platform android-arm64 --analyze-size` | Size analysis |

Current split APK sizes: arm64-v8a 20.4 MB, armeabi-v7a 18.4 MB, x86_64 21.7 MB. Universal APK is 59.5 MB. Material Symbols Rounded is tree-shaken from 15.1 MB to about 145 KB.

## Project layout

```
lib/
  app/            MaterialApp, router, theme, providers
  core/
    db/           Drift tables, database, DAOs, domain errors
    dates/        Local date keys and subscription due calculation
    money/        Rupiah parsing, formatting, input formatter
    models/       Shared view models
    widgets/      Shared Material 3 widgets
  features/       home, wallets, transactions, analytics, subscriptions, debts, settings
  l10n/           Indonesian ARB and generated localizations
test/             Unit, DAO, widget, copy, and layout tests
openspec/         Capability specs and archived change history
android/          Android host, signing config, manifests
```

## Data and balances

SQLite database, schema version 1. Amounts are integer rupiah. Calendar dates are stored as `YYYY-MM-DD` local date keys.

| Table | Purpose |
| --- | --- |
| `wallets` | Kantong name, type, opening balance, icon, color, archive |
| `categories` | Income/expense categories, including system "Biaya Transfer" |
| `transactions` | Income and expense entries |
| `transfers` | One row per transfer, optional fee |
| `subscriptions` | Cycle, anchor day/month, lead days, next due date |
| `debt_entries` | Utang/piutang principal and optional linked transaction |
| `debt_payments` | Partial payments and optional linked transaction |
| `settings` | Theme mode and other preferences |

Balances are derived:

```
opening balance
+ income
- expenses
- outgoing transfers
- transfer fees
+ incoming transfers
```

Transfers do not count as income or expense. Fees do. Ledger entries do not affect wallets until committed.

## CI and releases

### First push

Create an empty GitHub repository, then connect this checkout:

```powershell
git remote add origin https://github.com/<owner>/<repository>.git
git add .
git commit -m "feat: build FerikMoney offline money management app"
git push -u origin main
```

GitHub Actions is enabled by default for the repository. The CI workflow runs on the first push.

### Continuous integration

`.github/workflows/ci.yml` runs on pushes to `main`, pull requests, and manual dispatch:

1. Flutter 3.50.1 and Java 21
2. `flutter pub get`
3. Drift and localization generation
4. `flutter analyze`
5. `flutter test`

### Android signing (one time)

Generate an upload keystore:

```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

If `keytool` is not on `PATH`, run it from Android Studio's bundled JDK (`...\Android Studio\jbr\bin\keytool.exe`).

Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

Both `android/key.properties` and `*.jks` are git-ignored. Back up the keystore and passwords; losing them prevents Play Store updates.

Add these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of `android/app/upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | `upload` |

Base64 encoding:

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
```

```bash
# Linux
base64 < android/app/upload-keystore.jks | tr -d '\n'
```

### Publish a release

```powershell
git tag v1.0.0
git push origin v1.0.0
```

`.github/workflows/release.yml` then:

1. Checks out the tag and derives `versionName` from it (`v1.0.0` → `1.0.0`).
2. Runs analysis and tests.
3. Restores the keystore when `ANDROID_KEYSTORE_BASE64` is set.
4. Builds split APKs and an AAB with `buildNumber = GITHUB_RUN_NUMBER`.
5. Publishes a GitHub Release containing:
   - `ferik-money-<version>-arm64-v8a.apk`
   - `ferik-money-<version>-armeabi-v7a.apk`
   - `ferik-money-<version>-x86_64.apk`
   - `ferik-money-<version>.aab`
   - `SHA256SUMS.txt`

Choose the APK for the phone: `arm64-v8a` for most Android phones, `armeabi-v7a` for older 32-bit devices, `x86_64` for emulators.

To rebuild an existing tag, run **Actions → Release → Run workflow** and enter the tag. If signing secrets are missing, the workflow warns and produces debug-signed artifacts; configure signing before publishing to users.

Before tagging, confirm:

- CI is green on `main`.
- All four Android signing secrets are set.
- The tag is `v<major>.<minor>.<patch>`.

The AAB is ready for manual upload to Google Play. This repository does not push to Play automatically.

## Offline behavior

- No account, backend, telemetry, or cloud sync.
- No `INTERNET` permission in main, debug, or profile manifests.
- Subscription reminders appear only while the app is open; no OS notifications or background jobs.
- All data stays in the app's local SQLite file on the device.
- Version 1 has no app lock or database encryption; it relies on the device lock.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `flutter run` cannot connect or hot reload fails | Add `INTERNET` to the debug manifest temporarily, run, then remove it |
| Drift generated code is stale | `fvm dart run build_runner build` |
| Indonesian text changes do not appear | `fvm flutter gen-l10n` |
| Release tag is rejected | Use `v<major>.<minor>.<patch>`, for example `v1.2.3` |
| Release artifacts are debug-signed | Set all four Android signing secrets |
| Android build fails after SDK changes | Run `fvm flutter doctor -v` and check accepted licenses |
