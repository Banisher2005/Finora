# Finora 💸

**Finora** is a premium, offline-first personal finance tracker for Android, designed with a focus on privacy, aesthetics, and simplicity. Built with Flutter, it requires no cloud synchronization, logins, or banking integration—putting you completely in control of your financial data.

## ✨ Features

- **100% Offline & Private:** Your financial data never leaves your device. All information is stored securely on local device storage using Hive NoSQL.
- **Biometric App Lock:** Keep your data private with fingerprint, face unlock, or PIN/pattern protection.
- **Premium Design:** Enjoy a stunning iOS-inspired UI with frosted glass effects, smooth animations, and a modern dark/light mode toggle.
- **Smart Formatting:** Built specifically for the Indian locale, supporting the Indian comma format (e.g., 1,23,456) and intuitive word labels ("1.23 Lakh", "2.4 Crore") beneath figures.
- **Comprehensive Analytics:** Track your money using dynamic `fl_chart` visual breakdowns (pie charts and bar graphs) for income and expenses.
- **Custom PDF Reporting:** Generate and export detailed PDF reports spanning any custom date range. Share reports easily via Android's native share sheet.
- **Historical Management:** Fully browse, edit, or delete transactions from previous months using intuitive month-to-month navigation.
- **Reliable Backup/Restore:** Native path-based backup system allowing you to safely export and import JSON data to and from your device's Downloads folder.

## 🛠️ Technology Stack

- **Framework:** Flutter (Dart)
- **Local Database:** Hive / hive_flutter (Fast, lightweight NoSQL)
- **State Management:** Provider
- **UI / Aesthetics:** Material 3, Google Fonts (DM Sans & DM Serif Display), flutter_animate
- **Charts:** fl_chart
- **Exports:** pdf, printing, share_plus
- **Security:** local_auth

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.4.0 <4.0.0)
- Android Studio / Android SDK (minSdk 23 for biometric support)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Banisher2005/Finora.git
   cd Finora
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build APK (Release):**
   ```bash
   flutter build apk --release
   ```
   *The generated APK will be available in `build/app/outputs/flutter-apk/app-release.apk`.*

## 🔒 Permissions Used
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE`: Required for securely exporting/importing JSON backups to the public Downloads folder.
- `USE_BIOMETRIC` / `USE_FINGERPRINT`: Required for the app lock authentication.

## 🤝 Contribution
This project was designed for a single-user personal/family accounting use-case. Contributions, issues, and feature requests are welcome!

---
*Finora — Your finances, your privacy.*
