import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'database/hive_service.dart';
import 'providers/transaction_provider.dart';
import 'providers/report_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/security_provider.dart';
import 'providers/account_provider.dart';
import 'themes/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/saved_reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/account_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
  ]);
  await HiveService.initialize();
  await HiveService.migrateExistingData();
  await HiveService.checkAndCloseMonth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: const FinoraApp(),
    ),
  );
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();
  @override
  Widget build(BuildContext context) {
    final accProvider = context.watch<AccountProvider>();
    if (!accProvider.setupDone) {
      return AccountSetupScreen(
        onSetupComplete: () {
          // After setup, sync the active account to TransactionProvider
          final txProvider = context.read<TransactionProvider>();
          txProvider.setActiveAccount(accProvider.activeAccountId);
        },
      );
    }
    return LockScreen(child: const _AccountSync());
  }
}

/// Syncs the active account to TransactionProvider once at startup
class _AccountSync extends StatefulWidget {
  const _AccountSync();
  @override
  State<_AccountSync> createState() => _AccountSyncState();
}

class _AccountSyncState extends State<_AccountSync> {
  bool _synced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_synced) {
      final accProvider = context.read<AccountProvider>();
      final txProvider = context.read<TransactionProvider>();
      if (accProvider.activeAccountId.isNotEmpty) {
        txProvider.setActiveAccount(accProvider.activeAccountId);
      }
      _synced = true;
    }
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<Widget> _getScreens(VoidCallback onSeeAll) => [
    DashboardScreen(onSeeAll: onSeeAll),
    const TransactionsScreen(),
    const ReportsScreen(),
    const SavedReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColors.darkSurface : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(() => setState(() => _currentIndex = 1)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent, elevation: 0, height: 65,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Transactions'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder_rounded), label: 'Archive'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
