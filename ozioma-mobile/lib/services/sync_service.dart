import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'secure_db.dart';

/// Offline-first sync: Local is source of truth, PowerSync replicates to Postgres
/// Congregation Territory Assignment Sync:
/// - Territories table is congregation-scoped via RLS: congregation_id = auth.jwt() -> congregation_id
/// - Roles: elder can assign/unassign, publisher can only view assigned + update status/addresses
/// - LWW conflict resolution via updated_at, append-only for service_logs
class SyncService {
  final SecureDatabase db;
  late final PowerSyncDatabase powersync;
  SyncService({required this.db});

  Future<void> init() async {
    powersync = PowerSyncDatabase.withFactory(
      OpenFactory(path: 'ozioma_powersync.db'),
      schema: const Schema([
        Table('territories', [Column.text('id'), Column.text('number'), Column.text('name'), Column.text('boundary_geojson'), Column.text('status'), Column.text('assigned_to'), Column.text('congregation_id'), Column.text('due_date'), Column.text('updated_at')]),
        Table('addresses', [Column.text('id'), Column.text('territory_id'), Column.text('street_address'), Column.text('unit'), Column.text('status'), Column.real('latitude'), Column.real('longitude'), Column.integer('sort_order'), Column.text('updated_at')]),
        Table('return_visits', [Column.text('id'), Column.text('address_id'), Column.text('name'), Column.text('phone'), Column.text('preferred_time'), Column.text('language'), Column.text('family_details'), Column.integer('is_bible_study'), Column.text('created_at'), Column.text('updated_at')]),
        Table('visit_logs', [Column.text('id'), Column.text('return_visit_id'), Column.text('visit_date'), Column.text('notes'), Column.text('topics'), Column.text('scriptures'), Column.text('publications'), Column.text('next_question')]),
        Table('service_logs', [Column.text('id'), Column.text('user_id'), Column.text('log_date'), Column.integer('duration_minutes'), Column.integer('bible_studies_count'), Column.integer('synced')]),
      ]),
    );
    await powersync.initialize();

    final connector = SupabaseConnector();
    powersync.connect(connector: connector);
  }
}

class SupabaseConnector extends PowerSyncBackendConnector {
  final supabase = Supabase.instance.client;
  PowerSyncDatabase? _db;

  @override Future<void> init() async {}

  @override Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;
    return PowerSyncCredentials(
      endpoint: 'https://YOUR_POWERSYNC_URL',
      token: session.accessToken,
    );
  }

  @override void setParams(PowerSyncDatabase db) { _db = db; }

  @override Future<void> uploadData(PowerSyncDatabase database) async {
    final batch = await database.getCrudBatch();
    if (batch == null) return;
    for (var op in batch.crud) {
      // LWW: server trusts updated_at, append-only for service_logs
      await supabase.from(op.table).upsert(op.opData);
    }
    await batch.complete();
  }
}
