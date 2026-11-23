# Ozioma: Comprehensive System Audit, Codebase Forensic Analysis & Strategic Target Architecture

**Platform Target:** Dual-Platform Field Ministry & Congregation Administration System (Mobile & Native Desktop)  
**Status:** Architectural Blueprint & Deep Technical Audit  
**Date:** November 2026  
**Audience:** Core Engineering Team, Product Architects, Security & Theocratic Domain Specialists  

---

## 1. Executive Summary & Forensic State of the Codebase

Ozioma ("Good News" in Igbo) is conceived as an offline-first, privacy-focused field ministry platform tailored for Jehovah's Witnesses operating in demanding environments—specifically high-density, low-connectivity urban hubs such as Port Harcourt, Lagos, and Calabar, Nigeria. 

The application promises to eliminate paper territory cards (S-13), prevent lost return visit records, withstand erratic GSM network conditions, enforce stringent householder data privacy, and provide seamless congregation synchronization between publishers and elders.

### The Forensic Reality
A thorough code audit of `ozioma-flutter` and its accompanying documentation reveals an immense divergence between the system described in the documentation and what actually exists in source code:

1. **Prototype Masquerading as Complete:**
   Over 70% of the UI screens in `lib/screens/` are single-line stubs, static placeholders, or fake animations (e.g., `dashboard_screen.dart`, `rv_screen.dart`, `timer_screen.dart`, `resources_screen.dart`).
2. **Dual-Database Disconnect (Drift vs. PowerSync):**
   The codebase contains two completely separate, unbridged SQLite databases running simultaneously:
   - `SecureDatabase` (Drift + SQLCipher) writing to `ozioma_encrypted.db`.
   - `PowerSyncDatabase` writing to `ozioma_powersync.db`.
   Neither database synchronizes with the other. Services write to one database while screens read from the other or bypass the local database entirely to make direct network REST calls to Supabase.
3. **Compilation Blockers & Missing Dependencies:**
   The codebase cannot compile as checked in. Crucial packages (`sqlcipher`, `powersync_sqlite`) are imported in code but absent from `pubspec.yaml`. Drift generated files (`secure_db.g.dart`) are missing. Deprecated Supabase v1 methods (`.execute()`) are invoked against Supabase v2.
4. **Missing Native Platform Wrappers:**
   The repository contains only `lib/` and `supabase/`. It lacks `android/`, `ios/`, `windows/`, `macos/`, and `linux/` platform folders, meaning no build runner, splash screen, native permissions, keystore configurations, or native background workers exist.
5. **Severe Privacy & Theocratic Compliance Gaps:**
   Despite claiming compliance with data privacy, householder names, visit logs, and personal family details are defined in plain PostgreSQL tables in `schema.sql` without End-to-End Encryption (E2EE), exposing sensitive non-public personal information in violation of the Nigerian Data Protection Act (NDPA 2023) and global GDPR standards.
6. **Absence of Desktop Architecture:**
   While the business requirements demand a congregation overseer suite, no desktop application exists. Porting or stretching mobile screens onto desktop fails to meet the needs of Territory Overseers managing complex GIS vector boundaries, printing S-13 territory assignment cards, and auditing congregation field service reports.

---

## 2. Structural & Architectural Audit

### 2.1 Directory Structure & Layer Separation
```
ozioma-flutter/
├── lib/
│   ├── screens/      # Mixed concerns: UI widgets + inline network calls + state
│   ├── services/     # Monolithic service classes with mixed responsibilities
│   ├── app.dart      # MaterialApp wrapper
│   └── main.dart     # Direct initialization without bootstrap orchestration
└── supabase/
    ├── powersync_rules.yaml
    └── schema.sql
```

#### Critical Gaps Identified:
- **No Clean Architecture / Domain Modeling:**
  There is no separation between Domain, Data, and Presentation layers. There are no entity models, value objects, use cases, or repository interfaces. Screens directly instantiate services or manipulate low-level database companions.
- **Orphaned and Duplicate Files:**
  The repository contains redundant duplicate files:
  - `lib/screens/shell.dart` (5 tabs) vs `lib/screens/shell_1.dart` (6 tabs).
  - `lib/screens/territories_screen.dart` (static stub) vs `lib/screens/territories_screen_1.dart` (hardcoded mock array with fake timer loop).
  - `lib/screens/territory_create_screen.dart` vs `lib/screens/territory_mapper_screen.dart` (parallel implementations of perimeter walking).
  - Multiple READMEs (`README.md`, `README_1.md`, `README_2.md`) documenting conflicting feature sets.
- **Absence of Navigation Architecture:**
  Navigation is handled via imperative `Navigator.push(context, MaterialPageRoute(...))`. Deep linking, stateful tab persistence, route guards (e.g., biometric authentication lock screen), and desktop URL/route handling are absent.

### 2.2 State Management
- `flutter_riverpod: ^2.5.1` is declared in `pubspec.yaml`, but the implementation is virtually non-existent.
- In `main.dart`, only two providers are defined:
  ```dart
  final databaseProvider = Provider<SecureDatabase>((_) => throw UnimplementedError());
  final syncServiceProvider = Provider<SyncService>((_) => throw UnimplementedError());
  ```
- Screens rely on `StatefulWidget` with local `setState()`, resulting in lost state on navigation, unmanaged subscriptions, and memory leaks.
- Streams (e.g., `Geolocator.getPositionStream`) are initialized inside `initState` or callbacks without proper cancellation, lifecycle listening, or pause-on-background handling.

---

## 3. Code-Level & Implementation Forensic Audit

### 3.1 Line-by-Line Critical Failures & Compilation Errors

| File | Line | Issue | Severity | Technical Impact |
| :--- | :--- | :--- | :--- | :--- |
| `secure_db.dart` | 5 | `import 'package:sqlcipher/sqlcipher.dart'` | **Blocker** | Package `sqlcipher` is not in `pubspec.yaml`. Project will not compile. |
| `secure_db.dart` | 8 | `part 'secure_db.g.dart';` | **Blocker** | Generated file does not exist. Class `_$SecureDatabase` cannot be resolved. |
| `sync_service.dart` | 2 | `import 'package:powersync_sqlite/powersync_sqlite.dart';` | **Blocker** | Package `powersync_sqlite` is not in `pubspec.yaml`. Compilation fails. |
| `sync_service.dart` | 56 | `await supabase.from(op.table).upsert(op.opData).execute();` | **Blocker** | Method `.execute()` was removed in Supabase v2.x. Throws NoSuchMethodError. |
| `main.dart` | 11-12 | Hardcoded `'YOUR_SUPABASE_URL'` | **Critical** | Runtime exception on startup when initializing Supabase client. |
| `territory_mapper_screen.dart` | 105 | `cos(latAvg * 3.14159 / 180)` | **Blocker** | Missing `import 'dart:math';`. Method `cos` undefined. |
| `territory_mapper_screen.dart` | 118 | Naive screen projection `50 + i * 2, 50 + i` | **Critical** | CustomPainter renders an arbitrary screen scribble instead of projecting GeoJSON coordinates to Mapbox viewport. |
| `assignment_service.dart` | 11, 15 | Direct Supabase calls bypassing local DB | **Architectural** | Breaks offline-first guarantees. App crashes when offline during assignment queries. |
| `congregation_field_map_screen.dart` | 86 | `brotherPins['you']?.let(...)` | **Code Smuggle** | Non-standard extension method attempting Kotlin-style `.let` on nullable annotation. |

### 3.2 Mock Illusions vs. Production Reality

The codebase presents several features as functional that are entirely simulated:

1. **Fake Offline Tile Downloader (`territories_screen_1.dart` & `territory_map_screen.dart`):**
   ```dart
   // Simulated progress in UI:
   for (var i = 1; i <= 10; i++) {
     await Future.delayed(Duration(milliseconds: 350));
     if (mounted) setState(() => progress[id] = i / 10);
   }
   ```
   *Forensic Finding:* The download button does not communicate with Mapbox `TileStore` or `OfflineManager`. It delays 3.5 seconds and disappears, misleading the user into believing maps were cached. In the field with zero signal, map tiles will be blank.

2. **Inert Service Timer (`timer_screen.dart`):**
   ```dart
   class _TimerScreenState extends State<TimerScreen> {
     Duration d = Duration.zero;
     bool run = false;
     // ...
     ElevatedButton(onPressed: () {}, child: Text(run ? 'Pause' : 'Start'))
   }
   ```
   *Forensic Finding:* The timer UI is completely static. The start button has an empty callback `onPressed: () {}`. There is no ticker, no background audio/foreground service, and no persistent state across app restarts.

3. **Simulated Territory Splitting (`territory_split_screen.dart`):**
   ```dart
   void _executeSplit() async {
     // 1. Use Turf.js equivalent or server-side ST_Split(PostGIS)...
     Navigator.pop(context);
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
       content: Text('Split complete: ${widget.territory['number']}A + ${widget.territory['number']}B')));
   }
   ```
   *Forensic Finding:* No polygon splitting occurs. No geometry operations exist. The UI simply pops and displays a fake snackbar.

4. **Simulated Real-Time Presence (`presence_service.dart` & `congregation_field_map_screen.dart`):**
   ```dart
   void _listenForBrothers() {
     Future.delayed(Duration(seconds: 2), () async {
       if (!shareLocation) return;
       // Hardcoded mock pins for Bro. Emeka and Sis. Grace
       final b1 = await pinManager!.create(PointAnnotationOptions(
         geometry: Point(coordinates: Position(6.990, 4.820)),
         textField: 'Bro. Emeka',
       ));
       // ...
     });
   }
   ```
   *Forensic Finding:* Location broadcasting does not consume Supabase Realtime presence updates. It injects static coordinates for fictional brothers after a 2-second delay.

---

## 4. UI/UX, Design System & Sunlight Ergonomics Audit

### 4.1 Field Ergonomics in West Africa & High Ambient Sunlight
The existing styling uses generic Material 3 defaults (`Color(0xFF0F172A)` seed, `Color(0xFFF8FAFC)` background) with subtle pastel progress indicators.

#### Critical Failures for Field Conditions:
1. **Unusable in Direct Equatorial Sunlight:**
   Publishers working door-to-door in Port Harcourt or Lagos face high ambient lux levels (>100,000 lux). Subtle grey text (`Colors.grey`), pastel badges (`#d1fae5`), and standard 4dp progress bars wash out completely.
2. **Poor Touch Target Sizing:**
   Door-to-door field logging requires rapid, one-handed inputs while walking or holding literature. The current touch targets violate the 48x48dp minimum accessible size (e.g., small 24x24 download icons and tiny filter chips).
3. **Severe Thermal & Battery Degradation:**
   Running continuous Mapbox OpenGL/Metal vector rendering alongside unthrottled `Geolocator.getPositionStream` (every 5 meters) causes aggressive thermal throttling on budget Android devices (e.g., Tecno, Infinix, Samsung Galaxy A-series) and drains a 5000mAh battery in under 2 hours under 34°C ambient heat.
4. **Lack of Haptic Feedback & Audio Confirmation:**
   When logging householder outcomes at a gate (Unvisited $\rightarrow$ Not At Home), publishers need physical haptic feedback (medium impact tick) and distinct sound cues so they do not have to stare at their screen in front of residents.

---

## 5. Data Synchronization, Security & Privacy Audit

### 5.1 The Broken Dual-Database Engine
The most severe architectural flaw is the simultaneous use of Drift and PowerSync without integration:

```
[UI Widgets / Screens]
      │
      ├───> Drift (SecureDatabase / SQLCipher) ───> [ozioma_encrypted.db] (Isolated local file)
      │
      ├───> PowerSyncDatabase ────────────────────> [ozioma_powersync.db] ───> [Supabase Postgres]
      │
      └───> Direct Supabase Client ───────────────> [Network Calls] (Fails when offline)
```

#### Why This Breaks the System:
- Drift manages tables `Territories`, `Addresses`, `ReturnVisits`, etc., in an encrypted database with PRAGMA keys.
- PowerSync creates its own SQLite database with a completely separate schema.
- When an elder assigns a territory via `AssignmentService`, it writes directly to Supabase over the network. PowerSync downloads it into `ozioma_powersync.db`. But the UI listens to Drift (`SecureDatabase`), which has no knowledge of the downloaded record!
- **Solution:** PowerSync must be configured with its official Drift integration (`powersync` + `drift` wrapping PowerSync's SQLite connection). There must be **one** database file, **one** connection, and **one** reactive query stream.

### 5.2 Theocratic Privacy & Legal Compliance (NDPA & GDPR)
The current database schema (`supabase/schema.sql`) stores householder names, phone numbers, family details, and personal visit notes in plaintext columns on Supabase Postgres:

```sql
create table return_visits (
  id uuid primary key default uuid_generate_v4(),
  address_id uuid references addresses(id),
  name text,
  phone text,
  preferred_time text,
  language text,
  family_details text,
  ...
);
```

#### Regulatory & Theocratic Violation:
- Branch office instructions for Jehovah's Witnesses strictly forbid maintaining centralized, unencrypted cloud registries of householder personal data without explicit legal consent.
- Under the Nigerian Data Protection Act (NDPA 2023) and GDPR, storing identifiable religious notes regarding householders on public cloud infrastructure without E2EE exposes elders, publishers, and the organization to severe regulatory liability.
- **Architectural Remedy:**
  - **Zero-Cloud PII Model:** Return visit notes, householder names, phone numbers, and spiritual interests remain strictly **local-only**, encrypted with AES-256-GCM via hardware keystore.
  - **Congregation Sync Scope:** Only anonymized territory metadata (boundary GeoJSON, territory number, assignment status, due date, address coordinates, and status: `unvisited`, `not_at_home`, `return_visit_exists`, `do_not_call`) synchronizes to the cloud.

---

## 6. The Native Desktop Paradigm vs. Mobile Porting

### 6.1 Why Porting or Stretching Mobile UI Fails
A mobile screen stretched across a 27-inch 4K or 1080p desktop monitor produces an unusable, inefficient interface with excessive whitespace, awkward thumb-centric navigation, and no support for desktop workflows.

### 6.2 The Desktop Mission: Congregation Administration & GIS Cartography
The desktop version serves a completely different primary user persona: the **Territory Servant**, **Service Overseer**, and **Congregation Secretary**.

| Mobile Application (Publisher Field Work) | Native Desktop Application (Overseer Administration) |
| :--- | :--- |
| **Primary User:** Field Publisher / Pioneer | **Primary User:** Territory Servant / Service Overseer / Secretary |
| **Context:** Outdoor, walking, sunlight, one-handed | **Context:** Indoor office, desk, dual-monitors, mouse & keyboard |
| **Hardware:** Touchscreen, GPS, cellular/offline, battery-constrained | **Hardware:** High-res displays, local storage, printer, fast CPU |
| **Core Workflow:** Door-to-door status logging, navigation, timer | **Core Workflow:** Territory boundary drawing, S-13 printing, analytics |
| **Data Scope:** 1-2 assigned territories, personal RVs | **Data Scope:** All 80+ congregation territories, all publishers |
| **Key Advantage:** Portability, sensor integration, camera, haptics | **Key Advantage:** Dense data tables, batch processing, GIS vector editing |

### 6.3 Dedicated Native Desktop Architecture
The desktop application must be engineered using desktop-native principles:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  OZIOMA DESKTOP WORKSPACE (Multi-Pane / Dense Data / Desktop Shortcuts)               │
├──────────────────┬───────────────────────────────────────┬─────────────────────────────┤
│ TERRITORY LIST   │ INTERACTIVE GIS MAP CANVAS            │ DETAIL & ASSIGNMENT PANEL   │
│ & STATUS FILTER  │ (High-precision mouse boundary tools) │ (Publisher records & S-13)  │
├──────────────────┼───────────────────────────────────────┼─────────────────────────────┤
│ Search: [      ] │ [Pan] [Draw Poly] [Split] [Snap Road] │ Territory #14: Oakwood      │
│                  │                                       │ Assigned: Bro. Emeka Okon   │
│ [#14] Oakwood 60%│   ┌───────────────────────────────┐   │ Date Assigned: 12-Oct-2026  │
│ [#15] GRA P2  10%│   │       TERRITORY #14           │   │ Due Date:      12 Feb 2027  │
│ [#16] Woji S   0%│   │                               │   ├─────────────────────────────┤
│ [#17] Trans-A 100%   │       (Vector Boundary)       │   │ STATS:                      │
│                  │   │   [Start Pin]                 │   │ • 142 Residential Homes     │
│ [Filter: All v]  │   │                [Stop Pin]     │   │ • 18 Return Visits Active   │
│ • Available (24) │   └───────────────────────────────┘   │ • 3 Do-Not-Calls (Locked)   │
│ • Assigned  (42) │ Coordinates: 4.8210 N, 6.9882 E       ├─────────────────────────────┤
│ • Overdue   (6)  │ Zoom: 16.4 | Projection: EPSG:4326    │ [Generate Printable S-13]   │
│                  │ Layer: OpenStreetMap / Satellite      │ [Batch Reassign] [Split]    │
├──────────────────┴───────────────────────────────────────┴─────────────────────────────┤
│ STATUS BAR: SQLite Local Encrypted | Sync: Connected (0.2s ago) | 84 Territories Loaded│
└────────────────────────────────────────────────────────────────────────────────────────┘
```

#### Core Desktop-Exclusive Capabilities:
1. **Precision Vector GIS Cartography:**
   - Mouse-driven boundary creation with Bezier curve smoothing and vertex snapping.
   - Polygon splitting via topological line intersection (carving a territory into #14A and #14B).
   - Automated boundary alignment to prevent gaps and overlaps between adjacent congregation borders.
2. **S-13 Territory Card Engine & Print Spooler:**
   - Native PDF rendering generating official S-13 territory assignment cards.
   - Batch printing: 4-up cards per A4 page with high-resolution vector mini-maps, boundary street list, and QR code for publisher mobile import.
3. **Bulk Excel/CSV Importer & Cleaners:**
   - Import master street and address lists exported from municipal or congregation spreadsheets.
   - Geocoding pipeline with offline address normalization.
4. **Multi-Window & Multi-Monitor Support:**
   - Detach the GIS Map onto a second monitor while keeping the assignment database on the primary screen.
5. **Circuit Overseer (CO) & S-8 Congregation Summary Engine:**
   - Aggregate reporting across the entire territory inventory: coverage frequency, unworked territories, pioneer assignment saturation, and annual S-4 summary exports.

---

## 7. Concrete Industry-Standard Target Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 OZIOMA DUAL-PLATFORM ARCHITECTURE                                │
├─────────────────────────────────────────┬────────────────────────────────────────────────────────┤
│       MOBILE PLATFORM (FLUTTER 3.24+)   │        DESKTOP PLATFORM (TAURI 2.0: RUST + REACT 19)   │
│ • Touch-Optimized Sunlight UI (OLED)    │ • Tri-Pane Dense Workspace (Nav, GIS Canvas, Inspector)│
│ • Offline GPS Tracking & Voice Guidance │ • High-Performance Rust GIS Engine (geo / geos)       │
│ • Quick-Log Door-to-Door Ergonomics     │ • Official S-13 Vector PDF Spooler & Batch Printing    │
│ • Biometric Hardware Lock (Keystore)    │ • Bulk Excel/CSV Master Street Importer & Keyring      │
└─────────────────────────────────────────┴────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             UNIFIED LOCAL DATA & PERSISTENCE LAYER                               │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ • Mobile: PowerSync Client with Drift SQLite Engine (Single Unified DB File: ozioma.db)          │
│ • Desktop: Native Rust SQLite (rusqlite/sqlx) / PowerSync synchronized with Postgres             │
│ • Hardware-Backed AES-256 Encryption (Android Keystore, iOS Keychain, OS Keyring)                │
│ • Zero-Cloud PII Encryption: Sensitive Return Visit Notes encrypted with Local Publisher Key     │
│ • Reactive Offline Query Streams (Drift Watchers + Riverpod on Mobile; Zustand/Query on Desktop) │
└──────────────────────────────────────────────────────────────────────────────────────────────────┤
                                    │
                           Delta Sync Stream
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                BACKEND CLOUD INFRASTRUCTURE                                      │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ • Supabase Postgres: Normalized Schema, Row Level Security (RLS) scoped to Congregation ID        │
│ • PowerSync Service: Dynamic Bucket Sync Rules (Territories, Status, Sync Delta Queues)          │
│ • Edge Functions: Assignment Push Notifications, S-88 Verification, Tile Pack Manifests          │
│ • Dedicated Supabase Storage / Cloudflare R2 CDN: Pre-Generated PMTiles/MBTiles Vector Tile Packs │
│   (Port Harcourt, Lagos Metro, Calabar) with HTTP Range Requests and Resumable Chunk Streaming   │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 7.1 Unified Local-First Database Architecture
To eliminate the dual-database bug, Drift is bound directly to PowerSync on mobile:

```dart
// ozioma-mobile/lib/core/database/database.dart
import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Territories,
  Addresses,
  ReturnVisitsLocal,   // Local-only, un-synced PII
  ServiceLogs,
  CongregationMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(PowerSyncDatabase powersync) : super(powersync.driftConnection);
  
  @override
  int get schemaVersion => 2;
}
```

### 7.2 Dedicated Cloudflare R2 / Supabase Storage Offline Tile Pipeline
```
OpenStreetMap / Geofabrik Nigeria PBF
            │
            ▼ (Planetiler / Tilemaker Vector Slicing: z0 - z16)
  PMTiles Archive (port_harcourt.pmtiles, lagos_metro.pmtiles, calabar.pmtiles)
            │
            ▼ Upload with SHA-256 Checksums
  Dedicated Supabase Storage / Cloudflare R2 Bucket (CDN Cached)
            │
            ▼ (Resumable Range Downloads via Dio / Native Rust HTTP)
  Local Tile Storage (Mobile: MapLibre/Mapbox Local PMTiles; Desktop: MapLibre GL JS)
```

### 7.3 Sunlight-Engineered Design Tokens
```dart
// ozioma-mobile/lib/core/theme/sunlight_palette.dart
class SunlightPalette {
  // Ultra-high luminance contrast for 100,000+ lux field conditions
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color highVisYellow = Color(0xFFFFD600);
  static const Color highVisCyan = Color(0xFF00E5FF);
  
  // Territory status indicators (high saturation)
  static const Color statusUnvisited = Color(0xFF757575);
  static const Color statusNotAtHome = Color(0xFFFF9100);
  static const Color statusReturnVisit = Color(0xFF00E676);
  static const Color statusDoNotCall = Color(0xFFFF1744);
}
```

---

## 8. Summary of Approved Decisions & Next Actions

1. **Architecture Formalized:**
   - **Mobile Platform:** Flutter 3.24+ with Riverpod 2.x and unified Drift-over-PowerSync.
   - **Desktop Platform:** Dedicated Tauri 2.0 (Rust backend with `geo`/`geos` + React 19 / TypeScript / MapLibre frontend).
   - **Vector Tile Delivery:** Dedicated Supabase Storage / Cloudflare R2 CDN serving PMTiles with HTTP range requests.
2. **Discard Fake / Stub Files:** Immediately deprecate and remove `shell_1.dart`, `territories_screen_1.dart`, and fake timer/progress implementations.
3. **Execute Unified PowerSync-Drift Integration:** Consolidate data persistence into a single encrypted database with hardware key management.
4. **Implement Zero-Cloud PII Encryption:** Protect householder data locally; sync only anonymized territory status and boundaries.
5. **Enforce Strict Architectural Guardrails:** Mandate clean architectural layers, Riverpod code generation, and 100% offline test coverage.
