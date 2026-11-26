import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../encryption/aes_cipher.dart';

class ServiceLogItem {
  final String id;
  final String logDate;
  final int durationMinutes;
  final int bibleStudiesCount;
  final int placementsCount;
  final int videoShowingsCount;
  final String startTime;
  final String endTime;
  final String activityType;
  final String partnerName;
  final String notes;

  ServiceLogItem({
    required this.id,
    required this.logDate,
    required this.durationMinutes,
    required this.bibleStudiesCount,
    required this.placementsCount,
    required this.videoShowingsCount,
    this.startTime = '',
    this.endTime = '',
    this.activityType = 'Door-to-Door',
    this.partnerName = '',
    this.notes = '',
  });

  factory ServiceLogItem.fromRow(
    Map<String, dynamic> row, {
    String startTime = '',
    String endTime = '',
    String activityType = 'Door-to-Door',
    String partnerName = '',
    String notes = '',
  }) {
    return ServiceLogItem(
      id: row['id'] as String,
      logDate: row['log_date'] as String? ?? '',
      durationMinutes: (row['duration_minutes'] as int?) ?? 0,
      bibleStudiesCount: (row['bible_studies_count'] as int?) ?? 0,
      placementsCount: (row['placements_count'] as int?) ?? 0,
      videoShowingsCount: (row['video_showings_count'] as int?) ?? 0,
      startTime: startTime,
      endTime: endTime,
      activityType: activityType,
      partnerName: partnerName,
      notes: notes,
    );
  }
}

class ServiceLogDao {
  final PowerSyncDatabase db;
  final AesCipherService? cipher;

  ServiceLogDao(this.db, [this.cipher]);

  Future<String> _safeDecrypt(String raw) async {
    if (raw.isEmpty || cipher == null) return '';
    try {
      return await cipher!.decrypt(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<String> _safeEncrypt(String raw) async {
    if (raw.isEmpty || cipher == null) return raw;
    return await cipher!.encrypt(raw);
  }

  /// Reactive watch stream of service logs for a specific month (YYYY-MM),
  /// enriched with local encrypted start/end time, partner, and activity details.
  Stream<List<ServiceLogItem>> watchMonthlyLogs(String yearMonth) {
    return db
        .watch(
          '''
          SELECT s.*, d.start_time, d.end_time, d.activity_type, d.partner_name_enc, d.notes_enc
          FROM service_logs s
          LEFT JOIN service_session_details_local d ON d.service_log_id = s.id
          WHERE s.log_date LIKE ?
          ORDER BY s.log_date DESC, s.updated_at DESC
          ''',
          parameters: ['$yearMonth%'],
        )
        .asyncMap((rows) async {
      final list = <ServiceLogItem>[];
      for (final r in rows) {
        final partner = await _safeDecrypt(r['partner_name_enc'] as String? ?? '');
        final notes = await _safeDecrypt(r['notes_enc'] as String? ?? '');
        list.add(
          ServiceLogItem.fromRow(
            r,
            startTime: r['start_time'] as String? ?? '',
            endTime: r['end_time'] as String? ?? '',
            activityType: r['activity_type'] as String? ?? 'Door-to-Door',
            partnerName: partner,
            notes: notes,
          ),
        );
      }
      return list;
    });
  }

  /// Reactive watch stream for a service year (Sept 1 to Aug 31).
  Stream<List<ServiceLogItem>> watchServiceYearLogs(int serviceYearEnd) {
    final startDate = '${serviceYearEnd - 1}-09-01';
    final endDate = '$serviceYearEnd-08-31';
    return db
        .watch(
          'SELECT * FROM service_logs WHERE log_date >= ? AND log_date <= ? ORDER BY log_date DESC',
          parameters: [startDate, endDate],
        )
        .map((rows) => rows.map((r) => ServiceLogItem.fromRow(r)).toList());
  }

  /// Logs a daily ministry service session with optional start/end times and partner details.
  Future<String> logSession({
    required String userId,
    required DateTime date,
    required Duration duration,
    int bibleStudiesCount = 0,
    int placementsCount = 0,
    int videoShowingsCount = 0,
    String startTime = '',
    String endTime = '',
    String activityType = 'Door-to-Door',
    String partnerName = '',
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final logDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final now = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO service_logs (
        id, user_id, log_date, duration_minutes, bible_studies_count,
        placements_count, video_showings_count, synced, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
      ''',
      [
        id,
        userId,
        logDate,
        duration.inMinutes,
        bibleStudiesCount,
        placementsCount,
        videoShowingsCount,
        now,
      ],
    );

    if (startTime.isNotEmpty || endTime.isNotEmpty || partnerName.isNotEmpty || notes.isNotEmpty || activityType != 'Door-to-Door') {
      final detailId = const Uuid().v4();
      await db.execute(
        '''
        INSERT INTO service_session_details_local (
          id, service_log_id, start_time, end_time, activity_type, partner_name_enc, notes_enc, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          detailId,
          id,
          startTime,
          endTime,
          activityType,
          await _safeEncrypt(partnerName),
          await _safeEncrypt(notes),
          now,
        ],
      );
    }

    return id;
  }

  /// Updates an existing service session and its local private details.
  Future<void> updateSession({
    required String id,
    required String logDate,
    required int durationMinutes,
    required int bibleStudiesCount,
    required int placementsCount,
    required int videoShowingsCount,
    String startTime = '',
    String endTime = '',
    String activityType = 'Door-to-Door',
    String partnerName = '',
    String notes = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE service_logs SET
        log_date = ?, duration_minutes = ?, bible_studies_count = ?,
        placements_count = ?, video_showings_count = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        logDate,
        durationMinutes,
        bibleStudiesCount,
        placementsCount,
        videoShowingsCount,
        now,
        id,
      ],
    );

    final existingDetail = await db.getAll(
      'SELECT id FROM service_session_details_local WHERE service_log_id = ?',
      [id],
    );
    final partnerEnc = await _safeEncrypt(partnerName);
    final notesEnc = await _safeEncrypt(notes);

    if (existingDetail.isEmpty) {
      await db.execute(
        '''
        INSERT INTO service_session_details_local (
          id, service_log_id, start_time, end_time, activity_type, partner_name_enc, notes_enc, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [const Uuid().v4(), id, startTime, endTime, activityType, partnerEnc, notesEnc, now],
      );
    } else {
      await db.execute(
        '''
        UPDATE service_session_details_local SET
          start_time = ?, end_time = ?, activity_type = ?, partner_name_enc = ?, notes_enc = ?, updated_at = ?
        WHERE service_log_id = ?
        ''',
        [startTime, endTime, activityType, partnerEnc, notesEnc, now, id],
      );
    }
  }

  /// Deletes a service session and its private local metadata.
  Future<void> deleteSession(String id) async {
    await db.execute('DELETE FROM service_session_details_local WHERE service_log_id = ?', [id]);
    await db.execute('DELETE FROM service_logs WHERE id = ?', [id]);
  }
}
