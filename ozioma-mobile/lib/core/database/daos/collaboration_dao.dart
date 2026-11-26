import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class SharedPinItem {
  final String id;
  final String congregationId;
  final String territoryId;
  final String createdBy;
  final String title;
  final String category;
  final double latitude;
  final double longitude;
  final String notes;
  final bool isActive;
  final String updatedAt;

  SharedPinItem({
    required this.id,
    required this.congregationId,
    required this.territoryId,
    required this.createdBy,
    required this.title,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.isActive,
    required this.updatedAt,
  });

  factory SharedPinItem.fromRow(Map<String, dynamic> r) {
    return SharedPinItem(
      id: r['id'] as String,
      congregationId: r['congregation_id'] as String? ?? '',
      territoryId: r['territory_id'] as String? ?? '',
      createdBy: r['created_by'] as String? ?? 'Publisher',
      title: r['title'] as String? ?? 'Pinned Location',
      category: r['category'] as String? ?? 'meeting_point',
      latitude: (r['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (r['longitude'] as num?)?.toDouble() ?? 0.0,
      notes: r['notes'] as String? ?? '',
      isActive: (r['is_active'] as int?) != 0,
      updatedAt: r['updated_at'] as String? ?? '',
    );
  }
}

class PublisherMessageItem {
  final String id;
  final String congregationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String channel;
  final String body;
  final String pinId;
  final String createdAt;

  PublisherMessageItem({
    required this.id,
    required this.congregationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.channel,
    required this.body,
    required this.pinId,
    required this.createdAt,
  });

  factory PublisherMessageItem.fromRow(Map<String, dynamic> r) {
    return PublisherMessageItem(
      id: r['id'] as String,
      congregationId: r['congregation_id'] as String? ?? '',
      senderId: r['sender_id'] as String? ?? '',
      senderName: r['sender_name'] as String? ?? 'Publisher',
      senderRole: r['sender_role'] as String? ?? 'publisher',
      channel: r['channel'] as String? ?? 'field_service',
      body: r['body'] as String? ?? '',
      pinId: r['pin_id'] as String? ?? '',
      createdAt: r['created_at'] as String? ?? '',
    );
  }
}

class PublisherLocationItem {
  final String id;
  final String congregationId;
  final String publisherId;
  final String displayName;
  final String role;
  final String territoryId;
  final double latitude;
  final double longitude;
  final bool isTracking;
  final String updatedAt;

  PublisherLocationItem({
    required this.id,
    required this.congregationId,
    required this.publisherId,
    required this.displayName,
    required this.role,
    required this.territoryId,
    required this.latitude,
    required this.longitude,
    required this.isTracking,
    required this.updatedAt,
  });

  factory PublisherLocationItem.fromRow(Map<String, dynamic> r) {
    return PublisherLocationItem(
      id: r['id'] as String,
      congregationId: r['congregation_id'] as String? ?? '',
      publisherId: r['publisher_id'] as String? ?? '',
      displayName: r['display_name'] as String? ?? 'Publisher',
      role: r['role'] as String? ?? 'publisher',
      territoryId: r['territory_id'] as String? ?? '',
      latitude: (r['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (r['longitude'] as num?)?.toDouble() ?? 0.0,
      isTracking: (r['is_tracking'] as int?) == 1,
      updatedAt: r['updated_at'] as String? ?? '',
    );
  }
}

/// Manages real-time Location Pin Sharing, Publisher Field Chat, and Live Publisher Tracking.
class CollaborationDao {
  final PowerSyncDatabase db;
  CollaborationDao(this.db);

  // =========================================================================
  // LOCATION MANAGEMENT & SHARED PINS CRUD
  // =========================================================================

  Stream<List<SharedPinItem>> watchSharedPins({String? congregationId}) {
    final query = congregationId == null || congregationId.isEmpty
        ? 'SELECT * FROM shared_pins WHERE is_active = 1 ORDER BY updated_at DESC'
        : 'SELECT * FROM shared_pins WHERE congregation_id = ? AND is_active = 1 ORDER BY updated_at DESC';
    final params = congregationId == null || congregationId.isEmpty ? <Object>[] : [congregationId];
    return db
        .watch(query, parameters: params)
        .map((rows) => rows.map(SharedPinItem.fromRow).toList());
  }

  Future<String> createSharedPin({
    required String congregationId,
    String territoryId = '',
    required String createdBy,
    required String title,
    required String category,
    required double latitude,
    required double longitude,
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO shared_pins (
        id, congregation_id, territory_id, created_by, title, category,
        latitude, longitude, notes, is_active, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)
      ''',
      [id, congregationId, territoryId, createdBy, title, category, latitude, longitude, notes, now],
    );
    return id;
  }

  Future<void> updateSharedPin({
    required String id,
    required String title,
    required String category,
    required double latitude,
    required double longitude,
    required String notes,
  }) async {
    await db.execute(
      '''
      UPDATE shared_pins SET
        title = ?, category = ?, latitude = ?, longitude = ?, notes = ?, updated_at = ?
      WHERE id = ?
      ''',
      [title, category, latitude, longitude, notes, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteSharedPin(String id) async {
    await db.execute('DELETE FROM shared_pins WHERE id = ?', [id]);
  }

  // =========================================================================
  // PUBLISHER CHAT CRUD
  // =========================================================================

  Stream<List<PublisherMessageItem>> watchMessages({
    String? congregationId,
    String channel = 'all',
  }) {
    final conditions = <String>[];
    final params = <Object>[];

    if (congregationId != null && congregationId.isNotEmpty) {
      conditions.add('congregation_id = ?');
      params.add(congregationId);
    }
    if (channel != 'all') {
      conditions.add('channel = ?');
      params.add(channel);
    }

    final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    return db
        .watch('SELECT * FROM publisher_messages $whereClause ORDER BY created_at DESC', parameters: params)
        .map((rows) => rows.map(PublisherMessageItem.fromRow).toList());
  }

  Future<String> sendMessage({
    required String congregationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String channel,
    required String body,
    String pinId = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO publisher_messages (
        id, congregation_id, sender_id, sender_name, sender_role,
        channel, body, pin_id, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, congregationId, senderId, senderName, senderRole, channel, body, pinId, now, now],
    );
    return id;
  }

  Future<void> updateMessage(String id, String body) async {
    await db.execute(
      'UPDATE publisher_messages SET body = ?, updated_at = ? WHERE id = ?',
      [body, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deleteMessage(String id) async {
    await db.execute('DELETE FROM publisher_messages WHERE id = ?', [id]);
  }

  // =========================================================================
  // LIVE PUBLISHER TRACKING SYNC
  // =========================================================================

  Stream<List<PublisherLocationItem>> watchTrackedPublishers({String? congregationId}) {
    final query = congregationId == null || congregationId.isEmpty
        ? 'SELECT * FROM publisher_locations WHERE is_tracking = 1 ORDER BY updated_at DESC'
        : 'SELECT * FROM publisher_locations WHERE congregation_id = ? AND is_tracking = 1 ORDER BY updated_at DESC';
    final params = congregationId == null || congregationId.isEmpty ? <Object>[] : [congregationId];
    return db
        .watch(query, parameters: params)
        .map((rows) => rows.map(PublisherLocationItem.fromRow).toList());
  }

  Future<void> upsertPublisherLocation({
    required String congregationId,
    required String publisherId,
    required String displayName,
    required String role,
    required String territoryId,
    required double latitude,
    required double longitude,
    bool isTracking = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await db.getAll(
      'SELECT id FROM publisher_locations WHERE publisher_id = ?',
      [publisherId],
    );
    if (existing.isEmpty) {
      await db.execute(
        '''
        INSERT INTO publisher_locations (
          id, congregation_id, publisher_id, display_name, role, territory_id,
          latitude, longitude, is_tracking, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          const Uuid().v4(),
          congregationId,
          publisherId,
          displayName,
          role,
          territoryId,
          latitude,
          longitude,
          isTracking ? 1 : 0,
          now,
        ],
      );
    } else {
      await db.execute(
        '''
        UPDATE publisher_locations SET
          congregation_id = ?, display_name = ?, role = ?, territory_id = ?,
          latitude = ?, longitude = ?, is_tracking = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          congregationId,
          displayName,
          role,
          territoryId,
          latitude,
          longitude,
          isTracking ? 1 : 0,
          now,
          existing.first['id'],
        ],
      );
    }
  }

  Future<void> stopTrackingPublisher(String publisherId) async {
    await db.execute(
      'UPDATE publisher_locations SET is_tracking = 0, updated_at = ? WHERE publisher_id = ?',
      [DateTime.now().toIso8601String(), publisherId],
    );
  }
}
