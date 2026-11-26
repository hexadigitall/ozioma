import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// Canonical theocratic roles & privilege capabilities.
class TheocraticRolePermissions {
  static const List<String> allRoles = [
    'elder',
    'servant',
    'regular_pioneer',
    'auxiliary_pioneer',
    'publisher',
  ];

  static String label(String role) {
    switch (role) {
      case 'elder':
        return 'Elder / Overseer';
      case 'servant':
        return 'Ministerial / Territory Servant';
      case 'regular_pioneer':
        return 'Regular Pioneer (50h)';
      case 'auxiliary_pioneer':
        return 'Auxiliary Pioneer (15h/30h)';
      default:
        return 'Publisher';
    }
  }

  static bool canManageCongregation(String role) => role == 'elder';
  static bool canManagePublishers(String role) => role == 'elder';
  static bool canManageTerritories(String role) => role == 'elder' || role == 'servant';
  static bool canAssignTerritories(String role) => role == 'elder' || role == 'servant';
  static bool canModerateChat(String role) => role == 'elder' || role == 'servant';
  static bool canViewCongregationReports(String role) => role == 'elder' || role == 'servant';
}

class CongregationItem {
  final String id;
  final String name;
  final String circuit;
  final String countryCode;
  final String kingdomHallAddress;
  final String meetingSchedule;

  CongregationItem({
    required this.id,
    required this.name,
    required this.circuit,
    required this.countryCode,
    required this.kingdomHallAddress,
    required this.meetingSchedule,
  });

  factory CongregationItem.fromRow(Map<String, dynamic> row) {
    return CongregationItem(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'Unnamed Congregation',
      circuit: row['circuit'] as String? ?? '',
      countryCode: row['country_code'] as String? ?? 'WW',
      kingdomHallAddress: row['kingdom_hall_address'] as String? ?? '',
      meetingSchedule: row['meeting_schedule'] as String? ?? '',
    );
  }
}

class PublisherProfileItem {
  final String id;
  final String congregationId;
  final String displayName;
  final String role;
  final String serviceGroup;
  final bool isActive;
  final String linkedUserId;

  PublisherProfileItem({
    required this.id,
    required this.congregationId,
    required this.displayName,
    required this.role,
    required this.serviceGroup,
    required this.isActive,
    this.linkedUserId = '',
  });

  factory PublisherProfileItem.fromRow(Map<String, dynamic> row) {
    return PublisherProfileItem(
      id: row['id'] as String,
      congregationId: row['congregation_id'] as String? ?? '',
      displayName: row['display_name'] as String? ?? 'Publisher',
      role: row['role'] as String? ?? 'publisher',
      serviceGroup: row['service_group'] as String? ?? 'Group 1',
      isActive: (row['is_active'] as int?) != 0,
      linkedUserId: row['linked_user_id'] as String? ?? '',
    );
  }
}

class ActiveSessionState {
  final String activePublisherId;
  final String activeCongregationId;
  final bool setupCompleted;

  const ActiveSessionState({
    required this.activePublisherId,
    required this.activeCongregationId,
    required this.setupCompleted,
  });
}

class CongregationReportItem {
  final String id;
  final String congregationId;
  final String publisherId;
  final String publisherName;
  final String yearMonth;
  final String publisherRole;
  final bool participated;
  final double hours;
  final double creditHours;
  final int bibleStudies;
  final String remarks;
  final String submittedAt;

  CongregationReportItem({
    required this.id,
    required this.congregationId,
    required this.publisherId,
    required this.publisherName,
    required this.yearMonth,
    required this.publisherRole,
    required this.participated,
    required this.hours,
    required this.creditHours,
    required this.bibleStudies,
    required this.remarks,
    required this.submittedAt,
  });

  factory CongregationReportItem.fromRow(Map<String, dynamic> row) {
    return CongregationReportItem(
      id: row['id'] as String,
      congregationId: row['congregation_id'] as String? ?? '',
      publisherId: row['publisher_id'] as String? ?? '',
      publisherName: row['publisher_name'] as String? ?? '',
      yearMonth: row['year_month'] as String? ?? '',
      publisherRole: row['publisher_role'] as String? ?? 'publisher',
      participated: (row['participated'] as int?) != 0,
      hours: (row['hours'] as num?)?.toDouble() ?? 0.0,
      creditHours: (row['credit_hours'] as num?)?.toDouble() ?? 0.0,
      bibleStudies: (row['bible_studies'] as int?) ?? 0,
      remarks: row['remarks'] as String? ?? '',
      submittedAt: row['submitted_at'] as String? ?? '',
    );
  }
}

/// Manages Congregation registration, Publisher profiles, Service Privileges/Roles,
/// active device session identity, and Congregation S-4 reporting rollups.
class CongregationDao {
  final PowerSyncDatabase db;
  CongregationDao(this.db);

  // =========================================================================
  // ACTIVE SESSION & SETUP STATE
  // =========================================================================

  Stream<ActiveSessionState?> watchActiveSession() {
    return db.watch('SELECT * FROM active_session_local LIMIT 1').map((rows) {
      if (rows.isEmpty) return null;
      final r = rows.first;
      return ActiveSessionState(
        activePublisherId: r['active_publisher_id'] as String? ?? '',
        activeCongregationId: r['active_congregation_id'] as String? ?? '',
        setupCompleted: (r['setup_completed'] as int?) == 1,
      );
    });
  }

  Future<void> setActiveSession({
    required String publisherId,
    required String congregationId,
    bool setupCompleted = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await db.getAll('SELECT id FROM active_session_local LIMIT 1');
    if (existing.isEmpty) {
      await db.execute(
        '''
        INSERT INTO active_session_local (
          id, active_publisher_id, active_congregation_id, setup_completed, updated_at
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        ['current_session', publisherId, congregationId, setupCompleted ? 1 : 0, now],
      );
    } else {
      await db.execute(
        '''
        UPDATE active_session_local SET
          active_publisher_id = ?, active_congregation_id = ?, setup_completed = ?, updated_at = ?
        WHERE id = ?
        ''',
        [publisherId, congregationId, setupCompleted ? 1 : 0, now, existing.first['id']],
      );
    }
  }

  // =========================================================================
  // CONGREGATIONS CRUD
  // =========================================================================

  Stream<List<CongregationItem>> watchCongregations() {
    return db
        .watch('SELECT * FROM congregations ORDER BY name ASC')
        .map((rows) => rows.map(CongregationItem.fromRow).toList());
  }

  Future<String> createCongregation({
    required String name,
    String circuit = '',
    String countryCode = 'WW',
    String kingdomHallAddress = '',
    String meetingSchedule = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO congregations (
        id, name, circuit, country_code, kingdom_hall_address, meeting_schedule, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, name, circuit, countryCode, kingdomHallAddress, meetingSchedule, now, now],
    );
    return id;
  }

  Future<void> updateCongregation({
    required String id,
    required String name,
    required String circuit,
    required String countryCode,
    required String kingdomHallAddress,
    required String meetingSchedule,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE congregations SET
        name = ?, circuit = ?, country_code = ?, kingdom_hall_address = ?, meeting_schedule = ?, updated_at = ?
      WHERE id = ?
      ''',
      [name, circuit, countryCode, kingdomHallAddress, meetingSchedule, now, id],
    );
  }

  Future<void> deleteCongregation(String id) async {
    await db.execute('DELETE FROM shared_pins WHERE congregation_id = ?', [id]);
    await db.execute('DELETE FROM publisher_messages WHERE congregation_id = ?', [id]);
    await db.execute('DELETE FROM publisher_locations WHERE congregation_id = ?', [id]);
    await db.execute('DELETE FROM congregation_publishers WHERE congregation_id = ?', [id]);
    await db.execute('DELETE FROM territories WHERE congregation_id = ?', [id]);
    await db.execute('DELETE FROM congregations WHERE id = ?', [id]);
  }

  // =========================================================================
  // PUBLISHERS & PRIVILEGE / ROLE MANAGEMENT CRUD
  // =========================================================================

  Stream<List<PublisherProfileItem>> watchPublishers({String? congregationId}) {
    final query = congregationId == null || congregationId.isEmpty
        ? 'SELECT * FROM congregation_publishers ORDER BY display_name ASC'
        : 'SELECT * FROM congregation_publishers WHERE congregation_id = ? ORDER BY display_name ASC';
    final params = congregationId == null || congregationId.isEmpty ? <Object>[] : [congregationId];
    return db
        .watch(query, parameters: params)
        .map((rows) => rows.map(PublisherProfileItem.fromRow).toList());
  }

  Stream<PublisherProfileItem?> watchActivePublisher() {
    return db
        .watch(
          '''
          SELECT p.* FROM congregation_publishers p
          JOIN active_session_local s ON s.active_publisher_id = p.id
          LIMIT 1
          ''',
        )
        .map((rows) => rows.isEmpty ? null : PublisherProfileItem.fromRow(rows.first));
  }

  Future<String> createPublisher({
    required String congregationId,
    required String displayName,
    String role = 'publisher',
    String serviceGroup = 'Group 1',
    bool isActive = true,
    String linkedUserId = '',
    bool setAsActiveOnDevice = false,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO congregation_publishers (
        id, congregation_id, display_name, role, service_group, is_active, linked_user_id, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, congregationId, displayName, role, serviceGroup, isActive ? 1 : 0, linkedUserId, now],
    );
    if (setAsActiveOnDevice) {
      await setActiveSession(publisherId: id, congregationId: congregationId);
    }
    return id;
  }

  Future<void> updatePublisher({
    required String id,
    required String displayName,
    required String role,
    required String serviceGroup,
    required bool isActive,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE congregation_publishers SET
        display_name = ?, role = ?, service_group = ?, is_active = ?, updated_at = ?
      WHERE id = ?
      ''',
      [displayName, role, serviceGroup, isActive ? 1 : 0, now, id],
    );
  }

  Future<void> assignPublisherPrivilege(String id, String role) async {
    await db.execute(
      'UPDATE congregation_publishers SET role = ?, updated_at = ? WHERE id = ?',
      [role, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> deletePublisher(String id) async {
    await db.execute('DELETE FROM congregation_publishers WHERE id = ?', [id]);
  }

  // =========================================================================
  // CONGREGATION S-4 FIELD SERVICE REPORTING ROLLUP CRUD
  // =========================================================================

  Stream<List<CongregationReportItem>> watchCongregationReports(
    String congregationId,
    String yearMonth,
  ) {
    final query = congregationId.isEmpty
        ? 'SELECT * FROM congregation_service_reports WHERE year_month = ? ORDER BY submitted_at DESC'
        : 'SELECT * FROM congregation_service_reports WHERE congregation_id = ? AND year_month = ? ORDER BY submitted_at DESC';
    final params = congregationId.isEmpty ? [yearMonth] : [congregationId, yearMonth];
    return db
        .watch(query, parameters: params)
        .map((rows) => rows.map(CongregationReportItem.fromRow).toList());
  }

  Future<String> submitCongregationReport({
    required String congregationId,
    required String publisherId,
    required String publisherName,
    required String yearMonth,
    required String publisherRole,
    required bool participated,
    required double hours,
    double creditHours = 0.0,
    required int bibleStudies,
    String remarks = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    final existing = await db.getAll(
      'SELECT id FROM congregation_service_reports WHERE publisher_id = ? AND year_month = ?',
      [publisherId, yearMonth],
    );

    if (existing.isEmpty) {
      final id = const Uuid().v4();
      await db.execute(
        '''
        INSERT INTO congregation_service_reports (
          id, congregation_id, publisher_id, publisher_name, year_month,
          publisher_role, participated, hours, credit_hours, bible_studies,
          remarks, submitted_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          id,
          congregationId,
          publisherId,
          publisherName,
          yearMonth,
          publisherRole,
          participated ? 1 : 0,
          hours,
          creditHours,
          bibleStudies,
          remarks,
          now,
          now,
        ],
      );
      return id;
    } else {
      final id = existing.first['id'] as String;
      await db.execute(
        '''
        UPDATE congregation_service_reports SET
          publisher_name = ?, publisher_role = ?, participated = ?, hours = ?,
          credit_hours = ?, bible_studies = ?, remarks = ?, submitted_at = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          publisherName,
          publisherRole,
          participated ? 1 : 0,
          hours,
          creditHours,
          bibleStudies,
          remarks,
          now,
          now,
          id,
        ],
      );
      return id;
    }
  }

  Future<void> deleteCongregationReport(String id) async {
    await db.execute('DELETE FROM congregation_service_reports WHERE id = ?', [id]);
  }
}
