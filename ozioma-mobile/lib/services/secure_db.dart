import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

part 'secure_db.g.dart';

class Territories extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get number => text()();
  TextColumn get name => text()();
  TextColumn get boundaryGeojson => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('assigned'))(); // available, assigned, completed
  TextColumn get assignedTo => text().nullable()(); // publisher id
  TextColumn get congregationId => text()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get updatedAt => text().clientDefault(() => DateTime.now().toIso8601String())();
  @override Set<Column> get primaryKey => {id};
}

class Addresses extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get territoryId => text().references(Territories, #id)();
  TextColumn get streetAddress => text()();
  TextColumn get unit => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('unvisited'))(); // unvisited, not_at_home, return_visit, do_not_call
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get updatedAt => text().clientDefault(() => DateTime.now().toIso8601String())();
  @override Set<Column> get primaryKey => {id};
}

class ReturnVisits extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get addressId => text().references(Addresses, #id)();
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get preferredTime => text().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get familyDetails => text().nullable()();
  BoolColumn get isBibleStudy => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get updatedAt => text().clientDefault(() => DateTime.now().toIso8601String())();
  @override Set<Column> get primaryKey => {id};
}

class VisitLogs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get returnVisitId => text().references(ReturnVisits, #id)();
  TextColumn get visitDate => text().clientDefault(() => DateTime.now().toIso8601String())();
  TextColumn get notes => text()();
  TextColumn get topics => text().nullable()();
  TextColumn get scriptures => text().nullable()();
  TextColumn get publications => text().nullable()();
  TextColumn get nextQuestion => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}

class ServiceLogs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get logDate => text()(); // YYYY-MM-DD
  IntColumn get durationMinutes => integer()();
  IntColumn get bibleStudiesCount => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  @override Set<Column> get primaryKey => {id};
}

class CongregationPublishers extends Table {
  TextColumn get id => text()();
  TextColumn get congregationId => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text().withDefault(const Constant('publisher'))(); // elder, servant, publisher
  @override Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Territories, Addresses, ReturnVisits, VisitLogs, ServiceLogs, CongregationPublishers])
class SecureDatabase extends _$SecureDatabase {
  SecureDatabase() : super(_openConnection());
  @override int get schemaVersion => 1;

  Future<void> init() async {
    // Key handling done in _openConnection
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'ozioma_encrypted.db',
      native: const DriftNativeOptions(
        // SQLCipher encryption via sqlite3_flutter_libs + custom setup
        setup: _setupCipher,
      ),
    );
  }

  static Future<void> _setupCipher(database) async {
    const storage = FlutterSecureStorage();
    var key = await storage.read(key: 'db_key');
    if (key == null) {
      key = const Uuid().v4().replaceAll('-','') + const Uuid().v4().replaceAll('-','');
      await storage.write(key: 'db_key', value: key);
    }
    // PRAGMA key for SQLCipher
    await database.execute("PRAGMA key = '$key';");
    await database.execute("PRAGMA cipher_compatibility = 4;");
  }
}
