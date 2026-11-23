import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync_schema.dart';

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
    final connector = OziomaSupabaseConnector();
    db.connect(connector: connector);
  }

  Future<String> _getDefaultDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/ozioma_unified.db';
  }
}

class OziomaSupabaseConnector extends PowerSyncBackendConnector {
  final supabase = Supabase.instance.client;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    // Use environment endpoint or fallback
    return PowerSyncCredentials(
      endpoint: 'https://sync.ozioma.org',
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final batch = await database.getCrudBatch();
    if (batch == null) return;

    for (var op in batch.crud) {
      final table = op.table;
      if (op.opData != null && (op.op == UpdateType.put || op.op == UpdateType.patch)) {
        final data = Map<String, dynamic>.from(op.opData!);
        await supabase.from(table).upsert(data);
      } else if (op.op == UpdateType.delete) {
        await supabase.from(table).delete().eq('id', op.id);
      }
    }

    await batch.complete();
  }
}
