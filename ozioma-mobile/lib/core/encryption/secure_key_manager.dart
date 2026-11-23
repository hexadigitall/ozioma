import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key manager that generates, stores and retrieves the 256-bit AES master key
/// using hardware-backed keystores (Android Keystore / iOS Keychain).
class SecureKeyManager {
  static const _keyAlias = 'ozioma_master_keystore_key_v1';
  final FlutterSecureStorage _storage;

  SecureKeyManager({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Retrieves the active AES-256 master key or securely generates one if not yet initialized.
  Future<String> getOrCreateMasterKey() async {
    var key = await _storage.read(key: _keyAlias);
    if (key == null || key.isEmpty) {
      key = _generateSecureKey();
      await _storage.write(key: _keyAlias, value: key);
    }
    return key;
  }

  /// Generates a cryptographically random 256-bit (32 bytes) key.
  static String _generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Emergency duress purge: completely deletes local encryption keys from hardware storage.
  Future<void> purgeKey() async {
    await _storage.delete(key: _keyAlias);
  }
}
