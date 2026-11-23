import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ozioma/core/encryption/secure_key_manager.dart';
import 'package:ozioma/core/encryption/aes_cipher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zero-Cloud PII Hardware Keystore & AES-256 Engine', () {
    late SecureKeyManager keyManager;
    late AesCipherService cipher;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      keyManager = SecureKeyManager();
      cipher = AesCipherService(keyManager);
    });

    test('Master key is generated with 256 bits and persists in keystore', () async {
      final key1 = await keyManager.getOrCreateMasterKey();
      expect(key1, isNotEmpty);
      expect(key1.length, greaterThanOrEqualTo(32));

      // Second retrieval returns identical persistent key
      final key2 = await keyManager.getOrCreateMasterKey();
      expect(key1, equals(key2));
    });

    test('Sensitive householder data is encrypted and decrypted losslessly', () async {
      const originalName = 'Bro. Chukwuemeka Eze';
      const originalNotes = 'Calls only on Saturday mornings; interested in Rev 21:3,4';

      final encryptedName = await cipher.encrypt(originalName);
      final encryptedNotes = await cipher.encrypt(originalNotes);

      // Verify ciphertext format has prefix and IV
      expect(encryptedName.startsWith('enc:v1:'), isTrue);
      expect(encryptedNotes.startsWith('enc:v1:'), isTrue);
      expect(encryptedName, isNot(equals(originalName)));

      // Decrypt and verify equality
      final decryptedName = await cipher.decrypt(encryptedName);
      final decryptedNotes = await cipher.decrypt(encryptedNotes);

      expect(decryptedName, equals(originalName));
      expect(decryptedNotes, equals(originalNotes));
    });

    test('Emergency duress key purge destroys decryption capability', () async {
      const original = 'Confidential Elder Notes';
      final encrypted = await cipher.encrypt(original);

      // Trigger duress purge
      await keyManager.purgeKey();
      cipher.clearMemory();

      // New key is generated upon re-request
      final decrypted = await cipher.decrypt(encrypted);
      // Decryption with new key must fail safely
      expect(decrypted, equals('[Decryption Error: Key Mismatch]'));
    });
  });
}
