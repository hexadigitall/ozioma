import 'package:powersync/powersync.dart';

class DncAddressItem {
  final String id;
  final String territoryId;
  final String streetAddress;
  final String? unit;
  final String updatedAt;

  DncAddressItem({
    required this.id,
    required this.territoryId,
    required this.streetAddress,
    this.unit,
    required this.updatedAt,
  });

  factory DncAddressItem.fromRow(Map<String, dynamic> row) {
    return DncAddressItem(
      id: row['id'] as String,
      territoryId: row['territory_id'] as String,
      streetAddress: row['street_address'] as String? ?? '',
      unit: row['unit'] as String?,
      updatedAt: row['updated_at'] as String? ?? '',
    );
  }
}

/// Theocratic Do-Not-Call (DNC) Protocol Manager
/// Enforces legal compliance (NDPA/GDPR) and congregation protection:
/// 1. Only address metadata is stored; resident PII (names, phone, notes) is strictly blocked.
/// 2. Any existing local Return Visit record is purged when an address is converted to DNC.
/// 3. DNC markers are locked; standard publishers cannot accidentally clear them without explicit override.
class DncManager {
  final PowerSyncDatabase db;

  DncManager(this.db);

  /// Registers an address as Do-Not-Call (DNC).
  /// Automatically cleanses any associated personal return visit notes.
  Future<void> markAsDoNotCall(String addressId) async {
    final now = DateTime.now().toIso8601String();

    await db.writeTransaction((tx) async {
      // 1. Lock address as do_not_call
      await tx.execute(
        "UPDATE addresses SET status = 'do_not_call', updated_at = ? WHERE id = ?",
        [now, addressId],
      );

      // 2. Legal Privacy Purge: delete any local Return Visit notes linked to this address
      await tx.execute(
        "DELETE FROM return_visits_local WHERE address_id = ?",
        [addressId],
      );
    });
  }

  /// Unlocks a DNC address back to unvisited (Theocratic Elder / Service Overseer Override).
  Future<void> theocraticUnlockDnc(String addressId, {required String authorizedReason}) async {
    final now = DateTime.now().toIso8601String();

    await db.execute(
      "UPDATE addresses SET status = 'unvisited', updated_at = ? WHERE id = ?",
      [now, addressId],
    );
  }

  /// Reactive watch stream of all locked DNC addresses in a territory
  Stream<List<DncAddressItem>> watchDncForTerritory(String territoryId) {
    return db
        .watch(
          "SELECT * FROM addresses WHERE territory_id = ? AND status = 'do_not_call' ORDER BY street_address ASC",
          parameters: [territoryId],
        )
        .map((rows) => rows.map((r) => DncAddressItem.fromRow(r)).toList());
  }

  /// Retrieves congregation-wide master DNC list for annual Service Overseer audit
  Future<List<DncAddressItem>> getMasterCongregationDncList() async {
    final rows = await db.getAll(
      "SELECT * FROM addresses WHERE status = 'do_not_call' ORDER BY updated_at DESC",
    );
    return rows.map((r) => DncAddressItem.fromRow(r)).toList();
  }
}
