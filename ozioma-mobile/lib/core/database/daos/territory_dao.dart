import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class TerritoryItem {
  final String id;
  final String number;
  final String name;
  final String region;
  final String? boundaryGeojson;
  final double? startLat;
  final double? startLng;
  final double? stopLat;
  final double? stopLng;
  final String status;
  final String? assignedTo;
  final String? dueDate;
  final double progress;

  TerritoryItem({
    required this.id,
    required this.number,
    required this.name,
    required this.region,
    this.boundaryGeojson,
    this.startLat,
    this.startLng,
    this.stopLat,
    this.stopLng,
    required this.status,
    this.assignedTo,
    this.dueDate,
    this.progress = 0.0,
  });

  factory TerritoryItem.fromRow(Map<String, dynamic> row, {double progress = 0.0}) {
    return TerritoryItem(
      id: row['id'] as String,
      number: row['number'] as String? ?? '#',
      name: row['name'] as String? ?? 'Untitled',
      region: row['region'] as String? ?? 'General',
      boundaryGeojson: row['boundary_geojson'] as String?,
      startLat: (row['start_lat'] as num?)?.toDouble(),
      startLng: (row['start_lng'] as num?)?.toDouble(),
      stopLat: (row['stop_lat'] as num?)?.toDouble(),
      stopLng: (row['stop_lng'] as num?)?.toDouble(),
      status: row['status'] as String? ?? 'available',
      assignedTo: row['assigned_to'] as String?,
      dueDate: row['due_date'] as String?,
      progress: progress,
    );
  }
}

class TerritoryDao {
  final PowerSyncDatabase db;
  TerritoryDao(this.db);

  /// Reactive watch stream of all congregation territories
  Stream<List<TerritoryItem>> watchTerritories({String? region}) {
    final query = region == null || region == 'All'
        ? 'SELECT * FROM territories ORDER BY number ASC'
        : 'SELECT * FROM territories WHERE region = ? ORDER BY number ASC';
    final params = region == null || region == 'All' ? <Object>[] : [region];

    return db.watch(query, parameters: params).map((rows) {
      return rows.map((r) => TerritoryItem.fromRow(r)).toList();
    });
  }

  /// Reactive watch stream of a single territory
  Stream<TerritoryItem?> watchTerritory(String id) {
    return db
        .watch('SELECT * FROM territories WHERE id = ?', parameters: [id])
        .map((rows) => rows.isNotEmpty ? TerritoryItem.fromRow(rows.first) : null);
  }

  /// Inserts a newly mapped perimeter territory
  Future<String> createTerritory({
    required String number,
    required String name,
    required String region,
    required String congregationId,
    required String boundaryGeojson,
    double? startLat,
    double? startLng,
    double? stopLat,
    double? stopLng,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO territories (
        id, number, name, region, congregation_id, boundary_geojson,
        start_lat, start_lng, stop_lat, stop_lng, status, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'available', ?)
      ''',
      [
        id,
        number,
        name,
        region,
        congregationId,
        boundaryGeojson,
        startLat,
        startLng,
        stopLat,
        stopLng,
        now,
      ],
    );

    return id;
  }

  Future<void> updateStatus(String id, String status) async {
    await db.execute(
      'UPDATE territories SET status = ?, updated_at = ? WHERE id = ?',
      [status, DateTime.now().toIso8601String(), id],
    );
  }
}
