import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../encryption/aes_cipher.dart';

/// Canonical spiritual progression milestone definition for Bible students.
class DiscipleshipMilestoneDef {
  final String key;
  final int order;
  final String title;
  final String subtitle;
  final String encouragement;

  const DiscipleshipMilestoneDef({
    required this.key,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.encouragement,
  });
}

const List<DiscipleshipMilestoneDef> canonicalStudentMilestones = [
  DiscipleshipMilestoneDef(
    key: 'started_study',
    order: 1,
    title: 'Started Bible Study',
    subtitle: 'Began systematic study of Enjoy Life Forever!',
    encouragement: 'Help student establish a regular weekly day and time.',
  ),
  DiscipleshipMilestoneDef(
    key: 'gave_witness',
    order: 2,
    title: 'Gave a Witness',
    subtitle: 'Shared what they are learning with family, friends, or peers',
    encouragement: 'Ask at each lesson: "Who can you share this encouraging point with?"',
  ),
  DiscipleshipMilestoneDef(
    key: 'attended_first_meeting',
    order: 3,
    title: 'Attended First Meeting',
    subtitle: 'Visited the Kingdom Hall or joined congregational meeting',
    encouragement: 'Introduce them warmly to brothers and sisters in the congregation.',
  ),
  DiscipleshipMilestoneDef(
    key: 'regular_meetings',
    order: 4,
    title: 'Regular Meeting Attendance',
    subtitle: 'Consistently attends Midweek and Weekend meetings',
    encouragement: 'Sit together and show them how to follow Watchtower & Meeting Workbook.',
  ),
  DiscipleshipMilestoneDef(
    key: 'made_comment',
    order: 5,
    title: 'Made Comment at Meeting',
    subtitle: 'Expressed their faith publicly by commenting during Q&A',
    encouragement: 'Help them prepare one short, own-words comment before the meeting.',
  ),
  DiscipleshipMilestoneDef(
    key: 'first_assignment',
    order: 6,
    title: 'First Meeting Assignment',
    subtitle: 'Enrolled in Christian Life & Ministry school and completed first part',
    encouragement: 'Rehearse the Bible reading or demonstration together in advance.',
  ),
  DiscipleshipMilestoneDef(
    key: 'became_publisher',
    order: 7,
    title: 'Became a Publisher',
    subtitle: 'Approved as unbaptized publisher and shared in field ministry',
    encouragement: 'Arrange calm, encouraging first ministry sessions together.',
  ),
  DiscipleshipMilestoneDef(
    key: 'baptized',
    order: 8,
    title: 'Dedicated & Baptized',
    subtitle: 'Dedicated life to Jehovah and symbolized dedication by water baptism',
    encouragement: 'Continue finishing Enjoy Life Forever! and staying close after baptism.',
  ),
];

class ReturnVisitItem {
  final String id;
  final String addressId;
  final String territoryId;
  final String householderName;
  final String phoneNumber;
  final String addressText;
  final String preferredTime;
  final String language;
  final String studyPublication;
  final int currentLesson;
  final bool isBibleStudy;
  final String notes;
  final String goal;
  final String nextVisitDate;
  final String lastVisitDate;

  ReturnVisitItem({
    required this.id,
    required this.addressId,
    required this.territoryId,
    required this.householderName,
    required this.phoneNumber,
    this.addressText = '',
    required this.preferredTime,
    required this.language,
    this.studyPublication = 'Enjoy Life Forever! Book',
    required this.currentLesson,
    required this.isBibleStudy,
    required this.notes,
    this.goal = '',
    this.nextVisitDate = '',
    required this.lastVisitDate,
  });
}

class StudySessionItem {
  final String id;
  final String studentId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int lessonNumber;
  final String scriptures;
  final String summary;
  final String nextQuestion;

  StudySessionItem({
    required this.id,
    required this.studentId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.lessonNumber,
    required this.scriptures,
    required this.summary,
    required this.nextQuestion,
  });
}

class StudentQuestionItem {
  final String id;
  final String studentId;
  final String question;
  final String answer;
  final String scriptures;
  final bool isAnswered;
  final String createdAt;

  StudentQuestionItem({
    required this.id,
    required this.studentId,
    required this.question,
    required this.answer,
    required this.scriptures,
    required this.isAnswered,
    required this.createdAt,
  });
}

class StudentMilestoneItem {
  final String id;
  final String studentId;
  final String milestoneKey;
  final String achievedDate;
  final String notes;

  StudentMilestoneItem({
    required this.id,
    required this.studentId,
    required this.milestoneKey,
    required this.achievedDate,
    required this.notes,
  });
}

/// Zero-Cloud PII Return Visit & Discipleship DAO.
/// All personal details are encrypted locally with AES-256 via hardware keystore.
class ReturnVisitDao {
  final PowerSyncDatabase db;
  final AesCipherService cipher;

  ReturnVisitDao(this.db, this.cipher);

  Future<String> _safeDecrypt(String raw) async {
    if (raw.isEmpty) return '';
    try {
      return await cipher.decrypt(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<ReturnVisitItem> _mapReturnVisitRow(Map<String, dynamic> row) async {
    final name = await _safeDecrypt(row['householder_name_enc'] as String? ?? '');
    final phone = await _safeDecrypt(row['phone_enc'] as String? ?? '');
    final addr = await _safeDecrypt(row['address_text_enc'] as String? ?? '');
    final notes = await _safeDecrypt(row['notes_enc'] as String? ?? '');
    final goal = await _safeDecrypt(row['goal_enc'] as String? ?? '');

    return ReturnVisitItem(
      id: row['id'] as String,
      addressId: row['address_id'] as String? ?? '',
      territoryId: row['territory_id'] as String? ?? '',
      householderName: name,
      phoneNumber: phone,
      addressText: addr,
      preferredTime: row['preferred_time'] as String? ?? 'Any time',
      language: row['language'] as String? ?? 'English',
      studyPublication: row['study_publication'] as String? ?? 'Enjoy Life Forever! Book',
      currentLesson: (row['current_lesson'] as int?) ?? 1,
      isBibleStudy: (row['is_bible_study'] as int?) == 1,
      notes: notes,
      goal: goal,
      nextVisitDate: row['next_visit_date'] as String? ?? '',
      lastVisitDate: row['last_visit_date'] as String? ?? '',
    );
  }

  /// Reactive watch stream of Return Visits & Bible Students with transparent decryption.
  Stream<List<ReturnVisitItem>> watchReturnVisits() {
    return db.watch('SELECT * FROM return_visits_local ORDER BY updated_at DESC').asyncMap((rows) async {
      final items = <ReturnVisitItem>[];
      for (final row in rows) {
        items.add(await _mapReturnVisitRow(row));
      }
      return items;
    });
  }

  /// Reactive watch stream for a single Return Visit / Student by id.
  Stream<ReturnVisitItem?> watchReturnVisitById(String id) {
    return db
        .watch('SELECT * FROM return_visits_local WHERE id = ?', parameters: [id])
        .asyncMap((rows) async => rows.isEmpty ? null : await _mapReturnVisitRow(rows.first));
  }

  /// Creates a new Return Visit / Bible Student record with local AES-256 encryption.
  Future<String> createReturnVisit({
    required String addressId,
    required String territoryId,
    required String householderName,
    required String phoneNumber,
    String addressText = '',
    String preferredTime = 'Mornings',
    String language = 'English',
    String studyPublication = 'Enjoy Life Forever! Book',
    int currentLesson = 1,
    bool isBibleStudy = false,
    String notes = '',
    String goal = '',
    String nextVisitDate = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final nameEnc = await cipher.encrypt(householderName);
    final phoneEnc = await cipher.encrypt(phoneNumber);
    final addrEnc = await cipher.encrypt(addressText);
    final notesEnc = await cipher.encrypt(notes);
    final goalEnc = await cipher.encrypt(goal);

    await db.execute(
      '''
      INSERT INTO return_visits_local (
        id, address_id, territory_id, householder_name_enc, phone_enc, address_text_enc,
        preferred_time, language, study_publication, current_lesson, is_bible_study,
        notes_enc, goal_enc, next_visit_date, last_visit_date, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        addressId,
        territoryId,
        nameEnc,
        phoneEnc,
        addrEnc,
        preferredTime,
        language,
        studyPublication,
        currentLesson,
        isBibleStudy ? 1 : 0,
        notesEnc,
        goalEnc,
        nextVisitDate,
        now,
        now,
        now,
      ],
    );

    if (isBibleStudy) {
      await setStudentMilestone(
        studentId: id,
        milestoneKey: 'started_study',
        achievedDate: now.substring(0, 10),
        notes: 'Started studying $studyPublication (Lesson $currentLesson)',
      );
    }

    return id;
  }

  /// Updates an existing Return Visit / Bible Student profile.
  Future<void> updateReturnVisit({
    required String id,
    required String householderName,
    required String phoneNumber,
    required String addressText,
    required String preferredTime,
    required String language,
    required String studyPublication,
    required int currentLesson,
    required bool isBibleStudy,
    required String notes,
    required String goal,
    required String nextVisitDate,
  }) async {
    final now = DateTime.now().toIso8601String();
    final nameEnc = await cipher.encrypt(householderName);
    final phoneEnc = await cipher.encrypt(phoneNumber);
    final addrEnc = await cipher.encrypt(addressText);
    final notesEnc = await cipher.encrypt(notes);
    final goalEnc = await cipher.encrypt(goal);

    await db.execute(
      '''
      UPDATE return_visits_local SET
        householder_name_enc = ?,
        phone_enc = ?,
        address_text_enc = ?,
        preferred_time = ?,
        language = ?,
        study_publication = ?,
        current_lesson = ?,
        is_bible_study = ?,
        notes_enc = ?,
        goal_enc = ?,
        next_visit_date = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        nameEnc,
        phoneEnc,
        addrEnc,
        preferredTime,
        language,
        studyPublication,
        currentLesson,
        isBibleStudy ? 1 : 0,
        notesEnc,
        goalEnc,
        nextVisitDate,
        now,
        id,
      ],
    );
  }

  /// Deletes a Return Visit / Student and associated local study history.
  Future<void> deleteReturnVisit(String id) async {
    await db.execute('DELETE FROM study_sessions_local WHERE student_id = ?', [id]);
    await db.execute('DELETE FROM student_questions_local WHERE student_id = ?', [id]);
    await db.execute('DELETE FROM student_milestones_local WHERE student_id = ?', [id]);
    await db.execute('DELETE FROM return_visits_local WHERE id = ?', [id]);
  }

  Future<void> updateLesson(String id, int lesson) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'UPDATE return_visits_local SET current_lesson = ?, last_visit_date = ?, updated_at = ? WHERE id = ?',
      [lesson, now, now, id],
    );
  }

  // --- Study Sessions (Start/End times, Summaries, Next Question) ---

  Stream<List<StudySessionItem>> watchStudySessions(String studentId) {
    return db
        .watch(
          'SELECT * FROM study_sessions_local WHERE student_id = ? ORDER BY session_date DESC, start_time DESC',
          parameters: [studentId],
        )
        .asyncMap((rows) async {
      final list = <StudySessionItem>[];
      for (final row in rows) {
        list.add(
          StudySessionItem(
            id: row['id'] as String,
            studentId: row['student_id'] as String? ?? '',
            sessionDate: row['session_date'] as String? ?? '',
            startTime: row['start_time'] as String? ?? '',
            endTime: row['end_time'] as String? ?? '',
            durationMinutes: (row['duration_minutes'] as int?) ?? 0,
            lessonNumber: (row['lesson_number'] as int?) ?? 1,
            scriptures: row['scriptures'] as String? ?? '',
            summary: await _safeDecrypt(row['summary_enc'] as String? ?? ''),
            nextQuestion: await _safeDecrypt(row['next_question_enc'] as String? ?? ''),
          ),
        );
      }
      return list;
    });
  }

  Future<String> addStudySession({
    required String studentId,
    required String sessionDate,
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required int lessonNumber,
    required String scriptures,
    required String summary,
    required String nextQuestion,
    bool updateStudentLesson = true,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final summaryEnc = await cipher.encrypt(summary);
    final nextQEnc = await cipher.encrypt(nextQuestion);

    await db.execute(
      '''
      INSERT INTO study_sessions_local (
        id, student_id, session_date, start_time, end_time, duration_minutes,
        lesson_number, scriptures, summary_enc, next_question_enc, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        studentId,
        sessionDate,
        startTime,
        endTime,
        durationMinutes,
        lessonNumber,
        scriptures,
        summaryEnc,
        nextQEnc,
        now,
        now,
      ],
    );

    if (updateStudentLesson) {
      await updateLesson(studentId, lessonNumber);
    }
    return id;
  }

  Future<void> updateStudySession({
    required String id,
    required String sessionDate,
    required String startTime,
    required String endTime,
    required int durationMinutes,
    required int lessonNumber,
    required String scriptures,
    required String summary,
    required String nextQuestion,
  }) async {
    final now = DateTime.now().toIso8601String();
    final summaryEnc = await cipher.encrypt(summary);
    final nextQEnc = await cipher.encrypt(nextQuestion);

    await db.execute(
      '''
      UPDATE study_sessions_local SET
        session_date = ?, start_time = ?, end_time = ?, duration_minutes = ?,
        lesson_number = ?, scriptures = ?, summary_enc = ?, next_question_enc = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        sessionDate,
        startTime,
        endTime,
        durationMinutes,
        lessonNumber,
        scriptures,
        summaryEnc,
        nextQEnc,
        now,
        id,
      ],
    );
  }

  Future<void> deleteStudySession(String id) async {
    await db.execute('DELETE FROM study_sessions_local WHERE id = ?', [id]);
  }

  // --- Student Questions & Research References ---

  Stream<List<StudentQuestionItem>> watchStudentQuestions(String studentId) {
    return db
        .watch(
          'SELECT * FROM student_questions_local WHERE student_id = ? ORDER BY is_answered ASC, created_at DESC',
          parameters: [studentId],
        )
        .asyncMap((rows) async {
      final list = <StudentQuestionItem>[];
      for (final row in rows) {
        list.add(
          StudentQuestionItem(
            id: row['id'] as String,
            studentId: row['student_id'] as String? ?? '',
            question: await _safeDecrypt(row['question_enc'] as String? ?? ''),
            answer: await _safeDecrypt(row['answer_enc'] as String? ?? ''),
            scriptures: row['scriptures'] as String? ?? '',
            isAnswered: (row['is_answered'] as int?) == 1,
            createdAt: row['created_at'] as String? ?? '',
          ),
        );
      }
      return list;
    });
  }

  Stream<int> watchOpenQuestionCount() {
    return db
        .watch('SELECT COUNT(*) as cnt FROM student_questions_local WHERE is_answered = 0')
        .map((rows) => rows.isEmpty ? 0 : (rows.first['cnt'] as int? ?? 0));
  }

  Future<String> addStudentQuestion({
    required String studentId,
    required String question,
    String answer = '',
    String scriptures = '',
    bool isAnswered = false,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();
    final qEnc = await cipher.encrypt(question);
    final aEnc = await cipher.encrypt(answer);

    await db.execute(
      '''
      INSERT INTO student_questions_local (
        id, student_id, question_enc, answer_enc, scriptures, is_answered, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [id, studentId, qEnc, aEnc, scriptures, isAnswered ? 1 : 0, now, now],
    );
    return id;
  }

  Future<void> updateStudentQuestion({
    required String id,
    required String question,
    required String answer,
    required String scriptures,
    required bool isAnswered,
  }) async {
    final now = DateTime.now().toIso8601String();
    final qEnc = await cipher.encrypt(question);
    final aEnc = await cipher.encrypt(answer);

    await db.execute(
      '''
      UPDATE student_questions_local SET
        question_enc = ?, answer_enc = ?, scriptures = ?, is_answered = ?, updated_at = ?
      WHERE id = ?
      ''',
      [qEnc, aEnc, scriptures, isAnswered ? 1 : 0, now, id],
    );
  }

  Future<void> deleteStudentQuestion(String id) async {
    await db.execute('DELETE FROM student_questions_local WHERE id = ?', [id]);
  }

  // --- Student Discipleship Milestones Timeline ---

  Stream<List<StudentMilestoneItem>> watchStudentMilestones(String studentId) {
    return db
        .watch(
          'SELECT * FROM student_milestones_local WHERE student_id = ? ORDER BY achieved_date ASC',
          parameters: [studentId],
        )
        .asyncMap((rows) async {
      final list = <StudentMilestoneItem>[];
      for (final row in rows) {
        list.add(
          StudentMilestoneItem(
            id: row['id'] as String,
            studentId: row['student_id'] as String? ?? '',
            milestoneKey: row['milestone_key'] as String? ?? '',
            achievedDate: row['achieved_date'] as String? ?? '',
            notes: await _safeDecrypt(row['notes_enc'] as String? ?? ''),
          ),
        );
      }
      return list;
    });
  }

  Stream<Map<String, int>> watchMilestoneCountsByStudent() {
    return db
        .watch('SELECT student_id, COUNT(*) as cnt FROM student_milestones_local GROUP BY student_id')
        .map((rows) {
      final map = <String, int>{};
      for (final r in rows) {
        final sid = r['student_id'] as String? ?? '';
        if (sid.isNotEmpty) {
          map[sid] = (r['cnt'] as int?) ?? 0;
        }
      }
      return map;
    });
  }

  Future<void> setStudentMilestone({
    required String studentId,
    required String milestoneKey,
    required String achievedDate,
    String notes = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    final notesEnc = await cipher.encrypt(notes);
    final existing = await db.getAll(
      'SELECT id FROM student_milestones_local WHERE student_id = ? AND milestone_key = ?',
      [studentId, milestoneKey],
    );

    if (existing.isEmpty) {
      final id = const Uuid().v4();
      await db.execute(
        '''
        INSERT INTO student_milestones_local (
          id, student_id, milestone_key, achieved_date, notes_enc, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [id, studentId, milestoneKey, achievedDate, notesEnc, now],
      );
    } else {
      await db.execute(
        '''
        UPDATE student_milestones_local SET
          achieved_date = ?, notes_enc = ?, updated_at = ?
        WHERE id = ?
        ''',
        [achievedDate, notesEnc, now, existing.first['id']],
      );
    }
  }

  Future<void> removeStudentMilestone(String studentId, String milestoneKey) async {
    await db.execute(
      'DELETE FROM student_milestones_local WHERE student_id = ? AND milestone_key = ?',
      [studentId, milestoneKey],
    );
  }
}
