# Ozioma — Field Ministry App (Flutter + Supabase + PowerSync)

## What you asked for — built

**Architecture: Offline-first, local is primary**
- Flutter + drift + SQLCipher (AES-256 encrypted SQLite)
- Secure key in iOS Keychain / Android Keystore + Biometric lock (Face ID / Touch ID)
- PowerSync for background delta sync to Supabase Postgres
- Mapbox vector tile caching for offline maps

## Congregation Territory Assignment Sync (NEW)

**Flow:**
1. Elder creates territory in Supabase dashboard → RLS scoped to congregation_id
2. Elder assigns to publisher: `assigned_to = publisher_id, status='assigned', due_date`
3. PowerSync bucket `congregation_territories` pushes assignment to publisher device within seconds when online, or queued offline
4. Publisher works offline: logs addresses, RVs, status changes (unvisited→NH→RV→DNC)
5. On reconnect: PowerSync uploads CRUD batch with LWW (updated_at) conflict resolution. service_logs are append-only.
6. Elder sees live progress: % complete, return visits in territory, can reclaim or mark completed.

**Roles via RLS:**
- elder: full CRUD on all territories in congregation
- publisher: SELECT where congregation_id matches, UPDATE only own assigned addresses/RVs, INSERT service_logs

**Supabase Edge Function:** `notify-assignment` sends push when territory assigned.

## Setup

1. `flutter pub get`
2. Create Supabase project, run `supabase/schema.sql`
3. Deploy PowerSync rules: `supabase/powersync_rules.yaml`
4. Set `YOUR_SUPABASE_URL` and `YOUR_POWERSYNC_URL` in main.dart
5. `dart run build_runner build`
6. `flutter run`

## Local-first data model matches your spec exactly (UUID PKs for offline creation)

Tables: territories, addresses, return_visits, visit_logs, service_logs, congregation_publishers

## Security
- SQLCipher encrypted DB
- Biometric gate on app resume
- No householder data in cloud unless congregation opt-in (PowerSync filters)
- DNC list never leaves device unless explicitly synced (configurable)

Built for Port Harcourt low-signal field work.
