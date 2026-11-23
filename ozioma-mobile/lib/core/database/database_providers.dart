import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../encryption/secure_key_manager.dart';
import '../encryption/aes_cipher.dart';
import 'powersync_manager.dart';
import 'daos/territory_dao.dart';
import 'daos/address_dao.dart';
import 'daos/return_visit_dao.dart';
import 'daos/service_log_dao.dart';
import 'daos/dnc_manager.dart';

// Encryption providers
final secureKeyManagerProvider = Provider<SecureKeyManager>((ref) {
  return SecureKeyManager();
});

final aesCipherProvider = Provider<AesCipherService>((ref) {
  final keyManager = ref.watch(secureKeyManagerProvider);
  return AesCipherService(keyManager);
});

// Database & DAO providers
final powerSyncDatabaseProvider = Provider<PowerSyncManager>((ref) {
  return PowerSyncManager.instance;
});

final territoryDaoProvider = Provider<TerritoryDao>((ref) {
  final manager = ref.watch(powerSyncDatabaseProvider);
  return TerritoryDao(manager.db);
});

final addressDaoProvider = Provider<AddressDao>((ref) {
  final manager = ref.watch(powerSyncDatabaseProvider);
  return AddressDao(manager.db);
});

final returnVisitDaoProvider = Provider<ReturnVisitDao>((ref) {
  final manager = ref.watch(powerSyncDatabaseProvider);
  final cipher = ref.watch(aesCipherProvider);
  return ReturnVisitDao(manager.db, cipher);
});

final serviceLogDaoProvider = Provider<ServiceLogDao>((ref) {
  final manager = ref.watch(powerSyncDatabaseProvider);
  return ServiceLogDao(manager.db);
});

final dncManagerProvider = Provider<DncManager>((ref) {
  final manager = ref.watch(powerSyncDatabaseProvider);
  return DncManager(manager.db);
});
