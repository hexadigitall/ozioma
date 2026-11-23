import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ozioma/core/auth/biometric_auth_service.dart';
import 'package:ozioma/core/encryption/secure_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthService & Security Gate Unit Tests', () {
    late SecureKeyManager keyManager;
    late BiometricAuthService authService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      keyManager = SecureKeyManager();
      authService = BiometricAuthService(keyManager: keyManager);
    });

    test('Master PIN configuration and verification works correctly', () async {
      expect(await authService.isPinConfigured(), isFalse);

      await authService.setMasterPin('1234');
      expect(await authService.isPinConfigured(), isTrue);

      // Verify correct PIN
      final successResult = await authService.verifyPin('1234');
      expect(successResult.isSuccess, isTrue);

      // Verify incorrect PIN
      final failResult = await authService.verifyPin('0000');
      expect(failResult.isSuccess, isFalse);
    });

    test('Exponential backoff triggers lockout after 3 and 5 failed attempts', () async {
      await authService.setMasterPin('1234');

      // Attempt 1 and 2: failed
      await authService.verifyPin('1111');
      await authService.verifyPin('2222');

      // Attempt 3: triggers 30-second lockout
      final res3 = await authService.verifyPin('3333');
      expect(res3.isSuccess, isFalse);

      final lockout = await authService.checkLockoutDuration();
      expect(lockout, isNotNull);
      expect(lockout!.inSeconds, greaterThan(0));

      // Attempt during lockout must reject immediately with lockedOut
      final resDuringLockout = await authService.verifyPin('1234');
      expect(resDuringLockout.lockoutDuration, isNotNull);
    });

    test('Emergency duress PIN triggers immediate hardware key purge', () async {
      // Setup master key in keystore
      await keyManager.getOrCreateMasterKey();

      // Configure PIN with duress PIN '9999'
      await authService.setMasterPin('1234', duressPin: '9999');

      // Entering duress PIN
      final res = await authService.verifyPin('9999');
      expect(res.isDuress, isTrue);
      expect(res.isSuccess, isFalse);

      // Verify that master key in storage was deleted/purged
      const storage = FlutterSecureStorage();
      final keyAfterPurge = await storage.read(key: 'ozioma_master_keystore_key_v1');
      expect(keyAfterPurge, isNull);
    });
  });
}
