import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../encryption/aes_cipher.dart';

class ReturnVisitItem {
  final String id;
  final String addressId;
  final String territoryId;
  final String householderName;
  final String phoneNumber;
  final String preferredTime;
  final String language;
  final int currentLesson;
  final bool isBibleStudy;
  final String notes;
  final String lastVisitDate;

  ReturnVisitItem({
    required this.id,
    required this.addressId,
    required this.territoryId,
    required this.householderName,
    required this.phoneNumber,
    required this.preferredTime,
    required this.language,
    required this.currentLesson,
    required this.isBibleStudy,
    required this.notes,
    required this.lastVisitDate,
  });
}

/// Zero-Cloud PII Return Visit DAO.
/// Data is persisted into `return_visits_local` table and encrypted with AES-256 via hardware keystore.
class ReturnVisitDao {
  final PowerSyncDatabase db;
  final AesCipherService cipher;

  ReturnVisitDao(this.db, this.cipher);

  /// Reactive watch stream of Return Visits with transparent on-the-fly decryption
  Stream<List<ReturnVisitItem>> watchReturnVisits() {
    return db.watch('SELECT * FROM return_visits_local ORDER BY updated_at DESC').asyncMap((rows) async {
      final items = <ReturnVisitItem>[];
      for (var row in rows) {
        final name = await cipher.decrypt(row['householder_name_enc'] as String? ?? '');
        final phone = await cipher.decrypt(row['phone_enc'] as String? ?? '');
        final notes = await cipher.decrypt(row['notes_enc'] as String? ?? '');

        items.add(ReturnVisitItem(
          id: row['id'] as String,
          addressId: row['address_id'] as String? ?? '',
          territoryId: row['territory_id'] as String? ?? '',
          householderName: name,
          phoneNumber: phone,
          preferredTime: row['preferred_time'] as String? ?? 'Any time',
          language: row['language'] as String? ?? 'English',
          currentLesson: (row['current_lesson'] as int?) ?? 1,
          isBibleStudy: (row['is_bible_study'] as int?) == 1,
          notes: notes,
          lastVisitDate: row['last_visit_date'] as String? ?? '',
        ));
      }
      return items;
    });
  }

  /// Inserts a new return visit with local AES-256 hardware encryption
  Future<String> createReturnVisit({
    required String addressId,
    required String territoryId,
    required String householderName,
    required String phoneNumber,
    String preferredTime = 'Mornings',
    String language = 'English',
    int currentLesson = 1,
    bool isBibleStudy = false,
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    final nameEnc = await cipher.encrypt(householderName);
    final phoneEnc = await cipher.encrypt(phoneNumber);
    final notesEnc = await cipher.encrypt(notes);

    await db.execute(
      '''
      INSERT INTO return_visits_local (
        id, address_id, territory_id, householder_name_enc, phone_enc,
        preferred_time, language, current_lesson, is_bible_study,
        notes_enc, last_visit_date, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        addressId,
        territoryId,
        nameEnc,
        phoneEnc,
        preferredTime,
        language,
        currentLesson,
        isBibleStudy ? 1 : 0,
        notesEnc,
        now,
        now,
        now,
      ],
    );

    return id;
  }

  Future<void> updateLesson(String id, int lesson) async {
    final now = DateTime.now().toIso8601String();
    await db.execute(
      'UPDATE return_visits_local SET current_lesson = ?, updated_at = ? WHERE id = ?',
      [lesson, now, id],
    );
  }
}
