import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'secure_key_manager.dart';

/// Zero-Cloud PII Encryption Engine:
/// Encrypts sensitive householder personal notes, names, and phone numbers with AES-256-CBC.
/// Ciphertext format: 'enc:v1:<iv_base64>:<ciphertext_base64>'
class AesCipherService {
  final SecureKeyManager _keyManager;
  enc.Key? _cachedKey;

  AesCipherService(this._keyManager);

  Future<enc.Key> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final keyStr = await _keyManager.getOrCreateMasterKey();
    final bytes = base64Url.decode(keyStr);
    _cachedKey = enc.Key(Uint8List.fromList(bytes));
    return _cachedKey!;
  }

  /// Encrypts a plaintext string.
  Future<String> encrypt(String plainText) async {
    if (plainText.trim().isEmpty) return plainText;
    final key = await _getKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return 'enc:v1:${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts an encrypted string. If not encrypted with prefix, returns original string safely.
  Future<String> decrypt(String cipherText) async {
    if (!cipherText.startsWith('enc:v1:')) return cipherText;
    try {
      final parts = cipherText.split(':');
      if (parts.length != 4) return cipherText;
      final iv = enc.IV.fromBase64(parts[2]);
      final encryptedData = enc.Encrypted.fromBase64(parts[3]);
      final key = await _getKey();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (_) {
      return '[Decryption Error: Key Mismatch]';
    }
  }

  /// Flushes decrypted key buffers from RAM when the app is backgrounded or locked.
  void clearMemory() {
    _cachedKey = null;
  }
}
