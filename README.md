<div align="center">

# Finora

**A premium, offline-first personal finance tracker — built with Flutter, Provider & Hive.**

[![Flutter](https://img.shields.io/badge/Flutter-3-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

> **No login. No cloud sync. No ads.** Open the app and track your finances immediately in total privacy.

---

## Features

### Core Experience
| Feature | Description |
|---------|-------------|
| **Offline First** | Your financial data never leaves your device. Data is stored securely on local storage using Hive NoSQL. |
| **App Lock** | Keep your data private with biometric authentication (fingerprint, face unlock) or device PIN/pattern fallback. |
| **Indian Formatting** | Built specifically for the Indian locale, supporting the Indian comma format (e.g., 1,23,456) and intuitive word labels (1.23 Lakh, 2.4 Crore) beneath figures. |

### Analytics & Reporting
- **Dynamic Charts** — Track your money using visual breakdowns (pie charts and bar graphs) for income and expenses.
- **Custom PDF Export** — Generate and export detailed PDF reports spanning any custom date range. Share reports easily via Android's native share sheet.
- **Historical Management** — Browse, edit, or delete transactions from previous months using intuitive month-to-month navigation.

### Customisation & Design
- **Premium Design** — iOS-inspired UI with frosted glass effects, smooth animations, and clean layouts.
- **Theme Support** — Modern dark and light mode toggle.
- **Data Portability** — Native path-based backup system allowing you to safely export and import JSON data to and from your device's Downloads folder.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.4.0
- Android SDK (minSdk 23 for biometric support)

### Run Locally

```bash
# 1. Clone the repo
git clone https://github.com/Banisher2005/Finora.git
cd Finora

# 2. Install dependencies
flutter pub get

# 3. Start the dev server / run app
flutter run
```

### Build APK (Release)

```bash
flutter build apk --release
```
*The generated APK will be available in `build/app/outputs/flutter-apk/app-release.apk`.*

---

## Project Structure

```
Finora/
├── android/                  # Android native code and configurations
├── lib/
│   ├── database/             # Hive local storage implementations
│   ├── models/               # Data structures (Transaction, MonthlyReport)
│   ├── providers/            # State management (Theme, Transaction, Report, Security)
│   ├── screens/              # Main UI views (Dashboard, Transactions, Reports, Settings, Lock)
│   ├── themes/               # App color palettes and styling definitions
│   ├── utils/                # Date formatters, currency logic, PDF generator
│   └── widgets/              # Reusable UI components (TransactionTile, BalanceCard, etc.)
│   └── main.dart             # Application entry point
├── pubspec.yaml              # Dependencies and assets
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | [Flutter](https://flutter.dev/) |
| Language | [Dart](https://dart.dev/) |
| Local Database | Hive & hive_flutter (Fast NoSQL) |
| State Management | Provider |
| UI & Aesthetics | Material 3, Google Fonts, flutter_animate |
| Charts | fl_chart |
| Exports & Sharing | pdf, printing, share_plus |
| Security | local_auth |

---

## Permissions Used

- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE`: Required for securely exporting/importing JSON backups to the public Downloads folder.
- `USE_BIOMETRIC` / `USE_FINGERPRINT`: Required for the app lock authentication.

---

## License

[MIT](LICENSE) (c) 2026 [Banisher2005](https://github.com/Banisher2005)
