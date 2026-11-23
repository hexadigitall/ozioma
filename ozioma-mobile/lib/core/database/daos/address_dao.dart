import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class AddressItem {
  final String id;
  final String territoryId;
  final String streetAddress;
  final String? unit;
  final String status;
  final double? latitude;
  final double? longitude;
  final int sortOrder;

  AddressItem({
    required this.id,
    required this.territoryId,
    required this.streetAddress,
    this.unit,
    required this.status,
    this.latitude,
    this.longitude,
    this.sortOrder = 0,
  });

  factory AddressItem.fromRow(Map<String, dynamic> row) {
    return AddressItem(
      id: row['id'] as String,
      territoryId: row['territory_id'] as String,
      streetAddress: row['street_address'] as String? ?? '',
      unit: row['unit'] as String?,
      status: row['status'] as String? ?? 'unvisited',
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      sortOrder: (row['sort_order'] as int?) ?? 0,
    );
  }
}

class AddressDao {
  final PowerSyncDatabase db;
  AddressDao(this.db);

  /// Reactive watch stream of addresses within a territory
  Stream<List<AddressItem>> watchAddressesForTerritory(String territoryId) {
    return db
        .watch(
          'SELECT * FROM addresses WHERE territory_id = ? ORDER BY sort_order ASC, street_address ASC',
          parameters: [territoryId],
        )
        .map((rows) => rows.map((r) => AddressItem.fromRow(r)).toList());
  }

  /// Rapid 1-handed field door-to-door status update (Unvisited -> NH -> RV -> DNC)
  Future<void> updateStatus(String addressId, String newStatus) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'UPDATE addresses SET status = ?, updated_at = ? WHERE id = ?',
      [newStatus, now, addressId],
    );
  }

  /// Adds a new address to a territory
  Future<String> addAddress({
    required String territoryId,
    required String streetAddress,
    String? unit,
    double? lat,
    double? lng,
    String status = 'unvisited',
    int sortOrder = 0,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO addresses (id, territory_id, street_address, unit, status, latitude, longitude, sort_order, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, territoryId, streetAddress, unit, status, lat, lng, sortOrder, now],
    );

    return id;
  }
}
