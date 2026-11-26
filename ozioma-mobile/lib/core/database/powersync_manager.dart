import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync_schema.dart';
export '../utils/sync_conflict_resolver.dart';

/// Single unified local PowerSync database manager.
class PowerSyncManager {
  static PowerSyncManager? _instance;
  late final PowerSyncDatabase db;
  bool _initialized = false;

  PowerSyncManager._();

  static PowerSyncManager get instance => _instance ??= PowerSyncManager._();

  Future<void> initialize({String? customPath}) async {
    if (_initialized) return;

    final dbPath = customPath ?? await _getDefaultDbPath();

    db = PowerSyncDatabase(
      schema: powersyncSchema,
      path: dbPath,
    );

    await db.initialize();
    _initialized = true;

    // Connect to Supabase backend if active session exists
    try {
      final connector = OziomaSupabaseConnector();
      db.connect(connector: connector);
    } catch (e) {
      // Graceful offline fallback
    }
  }

  Future<String> _getDefaultDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/ozioma_unified.db';
  }
}

class OziomaSupabaseConnector extends PowerSyncBackendConnector {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final client = _supabase;
    if (client == null) return null;
    final session = client.auth.currentSession;
    if (session == null) return null;

    // Use environment endpoint or fallback
    return PowerSyncCredentials(
      endpoint: 'https://sync.ozioma.org',
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final client = _supabase;
    if (client == null) return;
    final batch = await database.getCrudBatch();
    if (batch == null) return;

    for (var op in batch.crud) {
      final table = op.table;
      try {
        if (op.opData != null && (op.op == UpdateType.put || op.op == UpdateType.patch)) {
          final data = Map<String, dynamic>.from(op.opData!);
          // Guarantee updated_at for LWW conflict resolution
          data['updated_at'] ??= DateTime.now().toUtc().toIso8601String();
          await client.from(table).upsert(data, onConflict: 'id');
        } else if (op.op == UpdateType.delete) {
          await client.from(table).delete().eq('id', op.id);
        }
      } catch (e) {
        rethrow;
      }
    }

    await batch.complete();
  }
}
