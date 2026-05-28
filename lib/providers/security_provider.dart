import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  static const _kLockEnabled = 'app_lock_enabled';

  final _auth = LocalAuthentication();
  bool _isLockEnabled = false;
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;

  /// Whether the app should block access (lock enabled AND not yet authenticated)
  bool get isLocked => _isLockEnabled && !_isAuthenticated;

  SecurityProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLockEnabled = prefs.getBool(_kLockEnabled) ?? false;
    notifyListeners();
  }

  Future<void> setLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLockEnabled, value);
    _isLockEnabled = value;
    if (!value) _isAuthenticated = true; // unlock immediately when disabling
    notifyListeners();
  }

  /// Call when app goes to background — require re-auth on next foreground
  void lockApp() {
    if (_isLockEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Trigger biometric / device-credential authentication
  Future<bool> authenticate(BuildContext context) async {
    if (!_isLockEnabled) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    // Check device capability
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canCheck && !isDeviceSupported) {
      // No biometrics AND no device PIN — just unlock
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    _isAuthenticating = true;
    notifyListeners();

    try {
      final result = await _auth.authenticate(
        localizedReason: 'Unlock Finora to access your finances',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN/pattern fallback
          sensitiveTransaction: false,
        ),
      );
      _isAuthenticated = result;
    } catch (_) {
      _isAuthenticated = false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }

    return _isAuthenticated;
  }
}
