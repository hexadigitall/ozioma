import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

class ServiceLogItem {
  final String id;
  final String logDate;
  final int durationMinutes;
  final int bibleStudiesCount;
  final int placementsCount;
  final int videoShowingsCount;

  ServiceLogItem({
    required this.id,
    required this.logDate,
    required this.durationMinutes,
    required this.bibleStudiesCount,
    required this.placementsCount,
    required this.videoShowingsCount,
  });

  factory ServiceLogItem.fromRow(Map<String, dynamic> row) {
    return ServiceLogItem(
      id: row['id'] as String,
      logDate: row['log_date'] as String,
      durationMinutes: (row['duration_minutes'] as int?) ?? 0,
      bibleStudiesCount: (row['bible_studies_count'] as int?) ?? 0,
      placementsCount: (row['placements_count'] as int?) ?? 0,
      videoShowingsCount: (row['video_showings_count'] as int?) ?? 0,
    );
  }
}

class ServiceLogDao {
  final PowerSyncDatabase db;
  ServiceLogDao(this.db);

  /// Reactive watch stream of service logs for a specific month (YYYY-MM)
  Stream<List<ServiceLogItem>> watchMonthlyLogs(String yearMonth) {
    return db
        .watch(
          "SELECT * FROM service_logs WHERE log_date LIKE ? ORDER BY log_date DESC",
          parameters: ['$yearMonth%'],
        )
        .map((rows) => rows.map((r) => ServiceLogItem.fromRow(r)).toList());
  }

  /// Logs a daily ministry service session
  Future<String> logSession({
    required String userId,
    required DateTime date,
    required Duration duration,
    int bibleStudiesCount = 0,
    int placementsCount = 0,
    int videoShowingsCount = 0,
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

    return id;
  }
}
