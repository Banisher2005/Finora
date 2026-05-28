import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_theme.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with WidgetsBindingObserver {
  bool _triedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-trigger auth shortly after first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final security = context.read<SecurityProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      security.lockApp();
    } else if (state == AppLifecycleState.resumed && security.isLocked) {
      _tryAuth();
    }
  }

  Future<void> _tryAuth() async {
    final security = context.read<SecurityProvider>();
    if (!security.isLocked) return;
    setState(() => _triedOnce = true);
    await security.authenticate(context);
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    // If not locked, show the actual app
    if (!security.isLocked) return widget.child;

    // Lock screen UI
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon / logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentBlue, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'DM Serif Display',
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 28),

                Text(
                  'Finora',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    fontFamily: 'DM Serif Display',
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Your financial data is protected',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),

                if (security.isAuthenticating)
                  const CircularProgressIndicator(color: AppColors.accentBlue)
                else ...[
                  // Fingerprint icon button
                  GestureDetector(
                    onTap: _tryAuth,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentBlue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 36,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleXY(begin: 1, end: 1.05, duration: 800.ms),
                  const SizedBox(height: 20),
                  Text(
                    _triedOnce ? 'Tap to try again' : 'Authenticating…',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
