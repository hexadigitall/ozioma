import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../encryption/secure_key_manager.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;
  final SecureKeyManager _keyManager;

  static const _pinHashKey = 'ozioma_security_pin_hash_v1';
  static const _duressPinHashKey = 'ozioma_duress_pin_hash_v1';
  static const _failedAttemptsKey = 'ozioma_failed_pin_attempts';
  static const _lockoutUntilKey = 'ozioma_lockout_until_epoch';

  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
    SecureKeyManager? keyManager,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _keyManager = keyManager ?? SecureKeyManager();

  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint or Face ID to unlock Ozioma',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPinConfigured() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setMasterPin(String pin, {String? duressPin}) async {
    final pinHash = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: pinHash);

    if (duressPin != null && duressPin.isNotEmpty) {
      final duressHash = _hashPin(duressPin);
      await _storage.write(key: _duressPinHashKey, value: duressHash);
    }
  }

  Future<Duration?> checkLockoutDuration() async {
    final lockoutEpochStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutEpochStr == null) return null;

    final lockoutEpoch = int.tryParse(lockoutEpochStr);
    if (lockoutEpoch == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (lockoutEpoch > now) {
      return Duration(milliseconds: lockoutEpoch - now);
    } else {
      await _storage.delete(key: _lockoutUntilKey);
      return null;
    }
  }

  /// Verifies entered PIN with support for exponential backoff lockout and duress purge.
  Future<PinVerificationResult> verifyPin(String enteredPin) async {
    // Check if currently locked out
    final lockout = await checkLockoutDuration();
    if (lockout != null) {
      return PinVerificationResult.lockedOut(lockout);
    }

    final enteredHash = _hashPin(enteredPin);

    // 1. Check for Emergency Duress PIN
    final duressHash = await _storage.read(key: _duressPinHashKey);
    if (duressHash != null && duressHash == enteredHash) {
      // Trigger immediate local key purge and emergency wipe
      await _keyManager.purgeKey();
      return PinVerificationResult.duressPurged();
    }

    // 2. Check for Master Security PIN
    final masterHash = await _storage.read(key: _pinHashKey);
    if (masterHash == null) {
      // If no PIN set, default to allowing unlock (first-run fallback)
      return PinVerificationResult.success();
    }

    if (masterHash == enteredHash) {
      await _resetFailedAttempts();
      return PinVerificationResult.success();
    } else {
      final remainingAttempts = await _recordFailedAttempt();
      return PinVerificationResult.failed(remainingAttempts: remainingAttempts);
    }
  }

  Future<int> _recordFailedAttempt() async {
    final countStr = await _storage.read(key: _failedAttemptsKey) ?? '0';
    var count = (int.tryParse(countStr) ?? 0) + 1;
    await _storage.write(key: _failedAttemptsKey, value: count.toString());

    if (count >= 5) {
      // 5-minute lockout
      final lockoutTime = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await _storage.write(key: _lockoutUntilKey, value: lockoutTime.toString());
      return 0;
    } else if (count >= 3) {
      // 30-second lockout
      final lockoutTime = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;
      await _storage.write(key: _lockoutUntilKey, value: lockoutTime.toString());
      return 5 - count;
    }

    return 5 - count;
  }

  Future<void> _resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  String _hashPin(String pin) {
    const salt = 'ozioma_salt_theocratic_field_2026';
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }
}

class PinVerificationResult {
  final bool isSuccess;
  final bool isDuress;
  final Duration? lockoutDuration;
  final int? remainingAttempts;

  PinVerificationResult._({
    required this.isSuccess,
    this.isDuress = false,
    this.lockoutDuration,
    this.remainingAttempts,
  });

  factory PinVerificationResult.success() => PinVerificationResult._(isSuccess: true);
  factory PinVerificationResult.duressPurged() => PinVerificationResult._(isSuccess: false, isDuress: true);
  factory PinVerificationResult.lockedOut(Duration duration) =>
      PinVerificationResult._(isSuccess: false, lockoutDuration: duration);
  factory PinVerificationResult.failed({int? remainingAttempts}) =>
      PinVerificationResult._(isSuccess: false, remainingAttempts: remainingAttempts);
}
