import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../encryption/aes_cipher.dart';

class MinistryAppointmentItem {
  final String id;
  final String partnerName;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String location;
  final String ministryType;
  final String specialFocus;
  final String notes;
  final String status;

  MinistryAppointmentItem({
    required this.id,
    required this.partnerName,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.ministryType,
    required this.specialFocus,
    required this.notes,
    required this.status,
  });
}

class MinistryGoalItem {
  final String id;
  final String title;
  final String category;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String period;
  final String notes;
  final bool isCompleted;
  final String dueDate;

  MinistryGoalItem({
    required this.id,
    required this.title,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.period,
    required this.notes,
    required this.isCompleted,
    required this.dueDate,
  });

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : (isCompleted ? 1.0 : 0.0);
}

class MinistryNoteItem {
  final String id;
  final String noteType;
  final String title;
  final String scripture;
  final String initialQuestion;
  final String talkingPoints;
  final String linkingQuestion;
  final String category;
  final bool isPinned;
  final String updatedAt;

  MinistryNoteItem({
    required this.id,
    required this.noteType,
    required this.title,
    required this.scripture,
    required this.initialQuestion,
    required this.talkingPoints,
    required this.linkingQuestion,
    required this.category,
    required this.isPinned,
    required this.updatedAt,
  });
}

class MonthlyReportRecord {
  final String id;
  final String yearMonth;
  final String publisherRole;
  final int monthlyHourGoal;
  final bool participatedInMinistry;
  final double hoursReported;
  final double creditHours;
  final int bibleStudiesCount;
  final String comments;
  final bool isSubmitted;
  final String submittedAt;

  MonthlyReportRecord({
    required this.id,
    required this.yearMonth,
    required this.publisherRole,
    required this.monthlyHourGoal,
    required this.participatedInMinistry,
    required this.hoursReported,
    required this.creditHours,
    required this.bibleStudiesCount,
    required this.comments,
    required this.isSubmitted,
    required this.submittedAt,
  });
}

/// DAO managing field service partner appointments, personal goals,
/// custom presentations/notes, congregation care initiatives, and S-4 reports.
class MinistryPlannerDao {
  final PowerSyncDatabase db;
  final AesCipherService cipher;

  MinistryPlannerDao(this.db, this.cipher);

  Future<String> _safeDecrypt(String raw) async {
    if (raw.isEmpty) return '';
    try {
      return await cipher.decrypt(raw);
    } catch (_) {
      return raw;
    }
  }

  // =========================================================================
  // FIELD SERVICE PARTNER APPOINTMENTS CRUD
  // =========================================================================

  Stream<List<MinistryAppointmentItem>> watchAppointments({String? statusFilter}) {
    final query = statusFilter == null || statusFilter == 'all'
        ? 'SELECT * FROM ministry_appointments_local ORDER BY appointment_date ASC, start_time ASC'
        : 'SELECT * FROM ministry_appointments_local WHERE status = ? ORDER BY appointment_date ASC, start_time ASC';
    final params = statusFilter == null || statusFilter == 'all' ? <Object>[] : [statusFilter];

    return db.watch(query, parameters: params).asyncMap((rows) async {
      final list = <MinistryAppointmentItem>[];
      for (final r in rows) {
        list.add(
          MinistryAppointmentItem(
            id: r['id'] as String,
            partnerName: await _safeDecrypt(r['partner_name_enc'] as String? ?? ''),
            appointmentDate: r['appointment_date'] as String? ?? '',
            startTime: r['start_time'] as String? ?? '09:00',
            endTime: r['end_time'] as String? ?? '11:30',
            location: await _safeDecrypt(r['location_enc'] as String? ?? ''),
            ministryType: r['ministry_type'] as String? ?? 'door_to_door',
            specialFocus: r['special_focus'] as String? ?? 'standard',
            notes: await _safeDecrypt(r['notes_enc'] as String? ?? ''),
            status: r['status'] as String? ?? 'scheduled',
          ),
        );
      }
      return list;
    });
  }

  Future<String> createAppointment({
    required String partnerName,
    required String appointmentDate,
    required String startTime,
    required String endTime,
    required String location,
    String ministryType = 'door_to_door',
    String specialFocus = 'standard',
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO ministry_appointments_local (
        id, partner_name_enc, appointment_date, start_time, end_time,
        location_enc, ministry_type, special_focus, notes_enc, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'scheduled', ?, ?)
      ''',
      [
        id,
        await cipher.encrypt(partnerName),
        appointmentDate,
        startTime,
        endTime,
        await cipher.encrypt(location),
        ministryType,
        specialFocus,
        await cipher.encrypt(notes),
        now,
        now,
      ],
    );
    return id;
  }

  Future<void> updateAppointment({
    required String id,
    required String partnerName,
    required String appointmentDate,
    required String startTime,
    required String endTime,
    required String location,
    required String ministryType,
    required String specialFocus,
    required String notes,
    required String status,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE ministry_appointments_local SET
        partner_name_enc = ?, appointment_date = ?, start_time = ?, end_time = ?,
        location_enc = ?, ministry_type = ?, special_focus = ?, notes_enc = ?, status = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        await cipher.encrypt(partnerName),
        appointmentDate,
        startTime,
        endTime,
        await cipher.encrypt(location),
        ministryType,
        specialFocus,
        await cipher.encrypt(notes),
        status,
        now,
        id,
      ],
    );
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'UPDATE ministry_appointments_local SET status = ?, updated_at = ? WHERE id = ?',
      [status, now, id],
    );
  }

  Future<void> deleteAppointment(String id) async {
    await db.execute('DELETE FROM ministry_appointments_local WHERE id = ?', [id]);
  }

  // =========================================================================
  // PERSONAL & SPIRITUAL GOALS CRUD
  // =========================================================================

  Stream<List<MinistryGoalItem>> watchGoals() {
    return db
        .watch('SELECT * FROM ministry_goals_local ORDER BY is_completed ASC, created_at DESC')
        .asyncMap((rows) async {
      final list = <MinistryGoalItem>[];
      for (final r in rows) {
        list.add(
          MinistryGoalItem(
            id: r['id'] as String,
            title: r['title'] as String? ?? '',
            category: r['category'] as String? ?? 'spiritual_routine',
            targetValue: (r['target_value'] as num?)?.toDouble() ?? 1.0,
            currentValue: (r['current_value'] as num?)?.toDouble() ?? 0.0,
            unit: r['unit'] as String? ?? 'items',
            period: r['period'] as String? ?? 'monthly',
            notes: await _safeDecrypt(r['notes_enc'] as String? ?? ''),
            isCompleted: (r['is_completed'] as int?) == 1,
            dueDate: r['due_date'] as String? ?? '',
          ),
        );
      }
      return list;
    });
  }

  Future<String> createGoal({
    required String title,
    required String category,
    required double targetValue,
    double currentValue = 0.0,
    required String unit,
    required String period,
    String notes = '',
    String dueDate = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final done = targetValue > 0 && currentValue >= targetValue;
    await db.execute(
      '''
      INSERT INTO ministry_goals_local (
        id, title, category, target_value, current_value, unit, period,
        notes_enc, is_completed, due_date, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        title,
        category,
        targetValue,
        currentValue,
        unit,
        period,
        await cipher.encrypt(notes),
        done ? 1 : 0,
        dueDate,
        now,
        now,
      ],
    );
    return id;
  }

  Future<void> updateGoal({
    required String id,
    required String title,
    required String category,
    required double targetValue,
    required double currentValue,
    required String unit,
    required String period,
    required String notes,
    required bool isCompleted,
    required String dueDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE ministry_goals_local SET
        title = ?, category = ?, target_value = ?, current_value = ?,
        unit = ?, period = ?, notes_enc = ?, is_completed = ?, due_date = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        title,
        category,
        targetValue,
        currentValue,
        unit,
        period,
        await cipher.encrypt(notes),
        isCompleted ? 1 : 0,
        dueDate,
        now,
        id,
      ],
    );
  }

  Future<void> updateGoalProgress(String id, double newCurrentValue, double targetValue) async {
    final now = DateTime.now().toIso8601String();
    final completed = targetValue > 0 && newCurrentValue >= targetValue;
    await db.execute(
      'UPDATE ministry_goals_local SET current_value = ?, is_completed = ?, updated_at = ? WHERE id = ?',
      [newCurrentValue, completed ? 1 : 0, now, id],
    );
  }

  Future<void> deleteGoal(String id) async {
    await db.execute('DELETE FROM ministry_goals_local WHERE id = ?', [id]);
  }

  // =========================================================================
  // PRESENTATIONS, NOTES & SPECIAL CONGREGATION INITIATIVES CRUD
  // =========================================================================

  Stream<List<MinistryNoteItem>> watchNotes({String? noteType}) {
    final query = noteType == null || noteType == 'all'
        ? 'SELECT * FROM ministry_notes_local ORDER BY is_pinned DESC, updated_at DESC'
        : 'SELECT * FROM ministry_notes_local WHERE note_type = ? ORDER BY is_pinned DESC, updated_at DESC';
    final params = noteType == null || noteType == 'all' ? <Object>[] : [noteType];

    return db.watch(query, parameters: params).asyncMap((rows) async {
      final list = <MinistryNoteItem>[];
      for (final r in rows) {
        list.add(
          MinistryNoteItem(
            id: r['id'] as String,
            noteType: r['note_type'] as String? ?? 'field_note',
            title: r['title'] as String? ?? '',
            scripture: r['scripture'] as String? ?? '',
            initialQuestion: r['initial_question'] as String? ?? '',
            talkingPoints: await _safeDecrypt(r['talking_points_enc'] as String? ?? ''),
            linkingQuestion: r['linking_question'] as String? ?? '',
            category: r['category'] as String? ?? 'General',
            isPinned: (r['is_pinned'] as int?) == 1,
            updatedAt: r['updated_at'] as String? ?? '',
          ),
        );
      }
      return list;
    });
  }

  Future<String> createNote({
    required String noteType,
    required String title,
    String scripture = '',
    String initialQuestion = '',
    required String talkingPoints,
    String linkingQuestion = '',
    String category = 'General',
    bool isPinned = false,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO ministry_notes_local (
        id, note_type, title, scripture, initial_question, talking_points_enc,
        linking_question, category, is_pinned, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        noteType,
        title,
        scripture,
        initialQuestion,
        await cipher.encrypt(talkingPoints),
        linkingQuestion,
        category,
        isPinned ? 1 : 0,
        now,
        now,
      ],
    );
    return id;
  }

  Future<void> updateNote({
    required String id,
    required String noteType,
    required String title,
    required String scripture,
    required String initialQuestion,
    required String talkingPoints,
    required String linkingQuestion,
    required String category,
    required bool isPinned,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      '''
      UPDATE ministry_notes_local SET
        note_type = ?, title = ?, scripture = ?, initial_question = ?,
        talking_points_enc = ?, linking_question = ?, category = ?, is_pinned = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        noteType,
        title,
        scripture,
        initialQuestion,
        await cipher.encrypt(talkingPoints),
        linkingQuestion,
        category,
        isPinned ? 1 : 0,
        now,
        id,
      ],
    );
  }

  Future<void> deleteNote(String id) async {
    await db.execute('DELETE FROM ministry_notes_local WHERE id = ?', [id]);
  }

  // =========================================================================
  // MONTHLY S-4 REPORT CONFIGURATION & SUBMISSION HISTORY
  // =========================================================================

  Stream<MonthlyReportRecord?> watchMonthlyReport(String yearMonth) {
    return db
        .watch('SELECT * FROM monthly_reports_local WHERE year_month = ?', parameters: [yearMonth])
        .asyncMap((rows) async {
      if (rows.isEmpty) return null;
      final r = rows.first;
      return MonthlyReportRecord(
        id: r['id'] as String,
        yearMonth: r['year_month'] as String? ?? yearMonth,
        publisherRole: r['publisher_role'] as String? ?? 'reg_pioneer',
        monthlyHourGoal: (r['monthly_hour_goal'] as int?) ?? 50,
        participatedInMinistry: (r['participated_in_ministry'] as int?) != 0,
        hoursReported: (r['hours_reported'] as num?)?.toDouble() ?? 0.0,
        creditHours: (r['credit_hours'] as num?)?.toDouble() ?? 0.0,
        bibleStudiesCount: (r['bible_studies_count'] as int?) ?? 0,
        comments: await _safeDecrypt(r['comments_enc'] as String? ?? ''),
        isSubmitted: (r['is_submitted'] as int?) == 1,
        submittedAt: r['submitted_at'] as String? ?? '',
      );
    });
  }

  Future<void> upsertMonthlyReport({
    required String yearMonth,
    required String publisherRole,
    required int monthlyHourGoal,
    required bool participatedInMinistry,
    required double hoursReported,
    required double creditHours,
    required int bibleStudiesCount,
    required String comments,
    required bool isSubmitted,
  }) async {
    final now = DateTime.now().toIso8601String();
    final commentsEnc = await cipher.encrypt(comments);
    final existing = await db.getAll(
      'SELECT id FROM monthly_reports_local WHERE year_month = ?',
      [yearMonth],
    );

    if (existing.isEmpty) {
      final id = const Uuid().v4();
      await db.execute(
        '''
        INSERT INTO monthly_reports_local (
          id, year_month, publisher_role, monthly_hour_goal, participated_in_ministry,
          hours_reported, credit_hours, bible_studies_count, comments_enc, is_submitted,
          submitted_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          id,
          yearMonth,
          publisherRole,
          monthlyHourGoal,
          participatedInMinistry ? 1 : 0,
          hoursReported,
          creditHours,
          bibleStudiesCount,
          commentsEnc,
          isSubmitted ? 1 : 0,
          isSubmitted ? now : '',
          now,
        ],
      );
    } else {
      await db.execute(
        '''
        UPDATE monthly_reports_local SET
          publisher_role = ?, monthly_hour_goal = ?, participated_in_ministry = ?,
          hours_reported = ?, credit_hours = ?, bible_studies_count = ?, comments_enc = ?,
          is_submitted = ?, submitted_at = ?, updated_at = ?
        WHERE id = ?
        ''',
        [
          publisherRole,
          monthlyHourGoal,
          participatedInMinistry ? 1 : 0,
          hoursReported,
          creditHours,
          bibleStudiesCount,
          commentsEnc,
          isSubmitted ? 1 : 0,
          isSubmitted ? now : '',
          now,
          existing.first['id'],
        ],
      );
    }
  }
}
