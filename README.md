# Finora

A premium, offline-first personal finance tracker — built with Flutter, Provider, and Hive.

> No login. No cloud sync. No ads. Open the app and track your finances immediately in total privacy.

## Features

### Core Experience

| Feature               | Description                                                                                                                                                           |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Offline First**     | Your financial data never leaves your device. Data is stored securely on local storage using Hive NoSQL.                                                              |
| **App Lock**          | Keep your data private with biometric authentication (fingerprint, face unlock) or device PIN/pattern fallback.                                                       |
| **Indian Formatting** | Built specifically for the Indian locale, supporting the Indian comma format (e.g., `1,23,456`) and intuitive word labels (`1.23 Lakh`, `2.4 Crore`) beneath figures. |

### Analytics & Reporting

* **Dynamic Charts** — Track your money using visual breakdowns such as pie charts and bar graphs for income and expenses.
* **Custom PDF Export** — Generate and export detailed PDF reports spanning any custom date range. Share reports easily via Android's native share sheet.
* **Historical Management** — Browse, edit, or delete transactions from previous months using intuitive month-to-month navigation.

### Account Management

* **Multiple Accounts** — Manage Cash, Bank Account, and additional accounts from a single interface.
* **Separate Balances** — View your total account balance independently from your available cash and bank balances.
* **Account Editing** — Edit account names, types, and details when your financial setup changes.
* **Account Safety** — Transactions and financial records remain linked to their respective accounts.
* **Account Migration** — Existing data and legacy account identifiers are migrated safely when updating the application.

### Loan Management

* **Loan Tracking** — Create and manage loans directly within Finora.
* **Loan Records** — Track loan amounts, outstanding balances, repayments, and related information.
* **Repayment Management** — Record repayments and keep loan balances updated.
* **Offline Loan Data** — Loan information is stored locally alongside the rest of your financial data.

### Customisation & Design

* **Premium Design** — iOS-inspired UI with frosted glass effects, smooth animations, and clean layouts.
* **Theme Support** — Modern dark and light mode toggle.
* **Updated Color System** — Distinct visual colors for income, expenses, cash, bank accounts, and other financial states.
* **Data Portability** — Native path-based backup system allowing you to safely export and import JSON data to and from your device's Downloads folder.
* **Backup Compatibility** — Improved support for importing backups created by previous versions of Finora.

## Getting Started

### Prerequisites

* Flutter SDK `>= 3.4.0`
* Android SDK
* Android `minSdk 23` for biometric support

### Run Locally

```bash
# 1. Clone the repository
git clone https://github.com/Banisher2005/Finora.git
cd Finora

# 2. Install dependencies
flutter pub get

# 3. Start the application
flutter run
```

### Build APK (Release)

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```text
Finora/
├── android/                  # Android native code and configurations
├── lib/
│   ├── database/             # Hive local storage implementations
│   ├── models/               # Data structures and financial models
│   ├── providers/            # State management and application logic
│   ├── screens/              # Main UI views and application screens
│   ├── themes/               # App color palettes and styling definitions
│   ├── utils/                # Date formatters, currency logic, PDF generator
│   ├── widgets/              # Reusable UI components
│   └── main.dart             # Application entry point
├── pubspec.yaml              # Dependencies and assets
└── README.md                 # Project documentation
```

## Tech Stack

| Layer             | Technology                                |
| ----------------- | ----------------------------------------- |
| Framework         | Flutter                                   |
| Language          | Dart                                      |
| Local Database    | Hive & hive_flutter                       |
| State Management  | Provider                                  |
| UI & Aesthetics   | Material 3, Google Fonts, flutter_animate |
| Charts            | fl_chart                                  |
| Exports & Sharing | pdf, printing, share_plus                 |
| Security          | local_auth                                |

## Data & Privacy

Finora is designed as an offline-first application.

* Financial data is stored locally on the user's device.
* No account or login is required.
* No cloud database is required.
* No financial data is transmitted to external servers.
* Backups are created manually by the user.
* Imported and exported backups use JSON format.

## Permissions Used

* `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE` — Used for exporting and importing JSON backups to the public Downloads folder where supported by Android.
* `USE_BIOMETRIC` / `USE_FINGERPRINT` — Required for biometric app-lock authentication.

> **Note:** Android's storage permission behavior varies by Android version. Finora uses the appropriate storage mechanism supported by the target Android version.

## Releases

Finora releases are distributed through GitHub Releases with Android APK builds.

### Current Releases

* `v1.1.0` — Loan System
* `v1.2.0` — Account Management and UI Update

## License

MIT © 2026 Banisher2005
