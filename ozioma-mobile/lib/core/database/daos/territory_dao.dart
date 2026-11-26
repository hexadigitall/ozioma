import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class TerritoryItem {
  final String id;
  final String number;
  final String name;
  final String region;
  final String congregationId;
  final String? boundaryGeojson;
  final double? startLat;
  final double? startLng;
  final double? stopLat;
  final double? stopLng;
  final String status;
  final String? assignedTo;
  final String? assignedDate;
  final String? dueDate;
  final double progress;
  final int totalAddresses;
  final int visitedAddresses;
  final int rvAddresses;
  final int dncAddresses;

  TerritoryItem({
    required this.id,
    required this.number,
    required this.name,
    required this.region,
    this.congregationId = '',
    this.boundaryGeojson,
    this.startLat,
    this.startLng,
    this.stopLat,
    this.stopLng,
    required this.status,
    this.assignedTo,
    this.assignedDate,
    this.dueDate,
    this.progress = 0.0,
    this.totalAddresses = 0,
    this.visitedAddresses = 0,
    this.rvAddresses = 0,
    this.dncAddresses = 0,
  });

  factory TerritoryItem.fromRow(
    Map<String, dynamic> row, {
    double? computedProgress,
    int totalAddresses = 0,
    int visitedAddresses = 0,
    int rvAddresses = 0,
    int dncAddresses = 0,
  }) {
    final status = row['status'] as String? ?? 'available';
    final fallbackProgress = status == 'completed' ? 1.0 : (status == 'assigned' ? 0.25 : 0.0);
    return TerritoryItem(
      id: row['id'] as String,
      number: row['number'] as String? ?? '#',
      name: row['name'] as String? ?? 'Untitled',
      region: row['region'] as String? ?? 'General',
      congregationId: row['congregation_id'] as String? ?? '',
      boundaryGeojson: row['boundary_geojson'] as String?,
      startLat: (row['start_lat'] as num?)?.toDouble(),
      startLng: (row['start_lng'] as num?)?.toDouble(),
      stopLat: (row['stop_lat'] as num?)?.toDouble(),
      stopLng: (row['stop_lng'] as num?)?.toDouble(),
      status: status,
      assignedTo: row['assigned_to'] as String?,
      assignedDate: row['assigned_date'] as String?,
      dueDate: row['due_date'] as String?,
      progress: computedProgress ?? fallbackProgress,
      totalAddresses: totalAddresses,
      visitedAddresses: visitedAddresses,
      rvAddresses: rvAddresses,
      dncAddresses: dncAddresses,
    );
  }
}

class TerritoryDao {
  final PowerSyncDatabase db;
  TerritoryDao(this.db);

  /// Reactive watch stream of congregation territories enriched with real address heatmap counts.
  Stream<List<TerritoryItem>> watchTerritories({String? region, String? congregationId}) {
    final conditions = <String>[];
    final params = <Object>[];

    if (region != null && region != 'All') {
      conditions.add('t.region = ?');
      params.add(region);
    }
    if (congregationId != null && congregationId.isNotEmpty) {
      conditions.add('t.congregation_id = ?');
      params.add(congregationId);
    }

    final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final query = '''
      SELECT t.*,
        COUNT(a.id) AS total_addr,
        SUM(CASE WHEN a.status IS NOT NULL AND a.status != 'unvisited' THEN 1 ELSE 0 END) AS visited_addr,
        SUM(CASE WHEN a.status = 'return_visit' THEN 1 ELSE 0 END) AS rv_addr,
        SUM(CASE WHEN a.status = 'do_not_call' THEN 1 ELSE 0 END) AS dnc_addr
      FROM territories t
      LEFT JOIN addresses a ON a.territory_id = t.id
      $whereClause
      GROUP BY t.id
      ORDER BY t.number ASC
    ''';

    return db.watch(query, parameters: params).map((rows) {
      return rows.map((r) {
        final total = (r['total_addr'] as int?) ?? 0;
        final visited = (r['visited_addr'] as int?) ?? 0;
        final rv = (r['rv_addr'] as int?) ?? 0;
        final dnc = (r['dnc_addr'] as int?) ?? 0;
        final pct = total > 0 ? (visited / total).clamp(0.0, 1.0) : null;
        return TerritoryItem.fromRow(
          r,
          computedProgress: pct,
          totalAddresses: total,
          visitedAddresses: visited,
          rvAddresses: rv,
          dncAddresses: dnc,
        );
      }).toList();
    });
  }

  /// Reactive watch stream of a single territory
  Stream<TerritoryItem?> watchTerritory(String id) {
    return db
        .watch('SELECT * FROM territories WHERE id = ?', parameters: [id])
        .map((rows) => rows.isNotEmpty ? TerritoryItem.fromRow(rows.first) : null);
  }

  /// Inserts a newly mapped or manually registered territory
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
    String status = 'available',
    String? assignedTo,
    String? dueDate,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO territories (
        id, number, name, region, congregation_id, boundary_geojson,
        start_lat, start_lng, stop_lat, stop_lng, status, assigned_to,
        assigned_date, due_date, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
        status,
        assignedTo,
        assignedTo != null ? now.substring(0, 10) : null,
        dueDate,
        now,
      ],
    );

    return id;
  }

  /// Full CRUD update for territory details, coordinates, and status
  Future<void> updateTerritory({
    required String id,
    required String number,
    required String name,
    required String region,
    required String status,
    String? assignedTo,
    String? dueDate,
    double? startLat,
    double? startLng,
    double? stopLat,
    double? stopLng,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE territories SET
        number = ?, name = ?, region = ?, status = ?, assigned_to = ?,
        due_date = ?, start_lat = ?, start_lng = ?, stop_lat = ?, stop_lng = ?, updated_at = ?
      WHERE id = ?
      ''',
      [number, name, region, status, assignedTo, dueDate, startLat, startLng, stopLat, stopLng, now, id],
    );
  }

  Future<void> assignTerritory({
    required String id,
    required String publisherName,
    required String dueDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE territories SET
        status = 'assigned', assigned_to = ?, assigned_date = ?, due_date = ?, updated_at = ?
      WHERE id = ?
      ''',
      [publisherName, now.substring(0, 10), dueDate, now, id],
    );
  }

  Future<void> returnTerritory(String id) async {
    await db.execute(
      '''
      UPDATE territories SET
        status = 'available', assigned_to = NULL, assigned_date = NULL, due_date = NULL, updated_at = ?
      WHERE id = ?
      ''',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> updateStatus(String id, String status) async {
    await db.execute(
      'UPDATE territories SET status = ?, updated_at = ? WHERE id = ?',
      [status, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteTerritory(String id) async {
    await db.execute('DELETE FROM addresses WHERE territory_id = ?', [id]);
    await db.execute('DELETE FROM shared_pins WHERE territory_id = ?', [id]);
    await db.execute('DELETE FROM territories WHERE id = ?', [id]);
  }
}
