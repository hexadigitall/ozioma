import 'package:powersync/powersync.dart';

/// Canonical PowerSync Client Schema matching PostgreSQL & Cloud replication rules.
/// Zero-Cloud PII: return_visits_local is strictly local and never synced to the cloud.
const powersyncSchema = Schema([
  Table('territories', [
    Column.text('number'),
    Column.text('name'),
    Column.text('region'),
    Column.text('boundary_geojson'),
    Column.real('start_lat'),
    Column.real('start_lng'),
    Column.real('stop_lat'),
    Column.real('stop_lng'),
    Column.text('status'),
    Column.text('assigned_to'),
    Column.text('congregation_id'),
    Column.text('assigned_date'),
    Column.text('due_date'),
    Column.text('updated_at'),
  ]),
  Table('addresses', [
    Column.text('territory_id'),
    Column.text('street_address'),
    Column.text('unit'),
    Column.text('status'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.integer('sort_order'),
    Column.text('updated_at'),
  ]),
  Table('service_logs', [
    Column.text('user_id'),
    Column.text('log_date'),
    Column.integer('duration_minutes'),
    Column.integer('bible_studies_count'),
    Column.integer('placements_count'),
    Column.integer('video_showings_count'),
    Column.integer('synced'),
    Column.text('updated_at'),
  ]),
  Table('profiles', [
    Column.text('congregation_id'),
    Column.text('display_name'),
    Column.text('role'),
    Column.text('updated_at'),
  ]),
  // LOCAL ONLY TABLE (Zero-Cloud PII: encrypted with AES-256 via hardware keystore)
  Table.localOnly('return_visits_local', [
    Column.text('address_id'),
    Column.text('territory_id'),
    Column.text('householder_name_enc'),
    Column.text('phone_enc'),
    Column.text('preferred_time'),
    Column.text('language'),
    Column.integer('current_lesson'),
    Column.integer('is_bible_study'),
    Column.text('notes_enc'),
    Column.text('last_visit_date'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);
