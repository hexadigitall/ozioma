# AGENTS.md — System Rules, Engineering Standards & Architectural Invariants

**Applicability:** All Autonomous Engineering Agents, Subagents & Human Developers  
**Repository:** `ozioma` (Field Ministry & Congregation Administration Platform)  
**Classification:** Canonical Single Source of Truth for Architecture & Code Generation  

---

## 1. Prime Directives & Non-Negotiable Invariants

Any code modification, PR, or architecture proposal must strictly adhere to these seven prime directives:

1. **Dual-Platform Paradigm Invariant:**
   - **Mobile (Flutter 3.24+ / Dart):** Built for touch, one-handed field walking, direct sunlight readability, low-power GPS tracking, and battery conservation in equatorial conditions.
   - **Native Desktop (Tauri 2.0: Rust + React 19 / TypeScript):** An administrative power-tool built for large screens, mouse precision, dense data grids, keyboard shortcuts, multi-windowing, and native hardware printing.
   - **STRICT PROHIBITION:** Never stretch, scale, or port a mobile layout to desktop. The desktop platform must be built independently within `ozioma-desktop/` using Tauri 2.0 with Rust for high-performance GIS geometry (`geo`/`geos`), native OS printing, and local SQLite/Keyring access.

2. **Single Unified Local-First Persistence Engine:**
   - **Mobile:** There must exist **only one** database file (`ozioma.db`). Drift must be instantiated using `PowerSyncDatabase.driftConnection`.
   - **Desktop:** Tauri core uses native Rust SQLite (`rusqlite` / `sqlx`) or PowerSync Web/Core SDK synchronized against the same Supabase/PowerSync schema.
   - **STRICT PROHIBITION:** Never instantiate a separate SQLite/Drift database alongside PowerSync. Never write to one database while reading from another.

3. **Zero-Cloud PII & Theocratic Privacy:**
   - Householder names, phone numbers, family details, and personal visit notes are classified as **Restricted Local PII**.
   - Restricted Local PII must remain local on the device, encrypted with AES-256-GCM via the OS hardware keystore (Android Keystore / iOS Keychain on Mobile; OS Keyring / Credential Manager on Desktop).
   - Cloud synchronization via PowerSync is limited to anonymized territory status, boundaries, and assignment metadata.
   - **STRICT PROHIBITION:** Never create Supabase tables, PowerSync rules, or API endpoints that transmit unencrypted householder personal notes to public cloud servers.

4. **Offline Primacy & Cloudflare R2 / Supabase CDN Vector Tile Distribution:**
   - The UI must **never** make direct HTTP/REST calls to Supabase to fetch or update application data. All reads are reactive streams from the local database.
   - Offline vector map tiles for Port Harcourt, Lagos Metro, and Calabar are packaged as PMTiles/MBTiles and distributed via a dedicated Supabase Storage bucket / Cloudflare R2 CDN with range-request and resume support.
   - **STRICT PROHIBITION:** Never implement mock download loops. Tile downloads must fetch real binary packages with verifiable SHA-256 checksums and stream into the local tile cache.

5. **No Fake Mocks or Simulated Delays in Production Code:**
   - **STRICT PROHIBITION:** Never commit mock `Future.delayed()` loops, fake progress bars, or placeholder SnackBar responses in place of real services. If a service (e.g., offline tile download, GIS polygon split) is pending, return an explicit `UnimplementedError` or feature flag rather than a cosmetic mock.

6. **Sunlight & Field Ergonomic Standards:**
   - Every mobile interactive element must meet a minimum bounding box of **$48\times 48\text{dp}$**.
   - Primary text in Sunlight Mode must pass **WCAG AAA** contrast ratios ($\ge 7:1$).
   - Quick-log status actions must provide haptic feedback (`HapticFeedback.lightImpact()`).

7. **Zero Analyzer Warnings & Test Coverage:**
   - The codebase must pass `flutter analyze` with **zero warnings** and **zero hints**.
   - Business logic in DAOs, sync rules, and polygon geometry must maintain $\ge 85\%$ automated unit test coverage.

---

## 2. Target Workspace & Multi-Platform Directory Structure

The repository is organized into distinct, specialized platforms sharing unified theocratic schemas:

```
ozioma/
├── ozioma-mobile/                             # Flutter 3.24+ Mobile Client (Android & iOS)
│   ├── lib/
│   │   ├── app.dart                           # Application root & theme router
│   │   ├── bootstrap.dart                     # Async initialization (Keystore, PowerSync, Drift)
│   │   ├── main.dart                          # Mobile entry point
│   │   ├── core/                              # Cross-cutting concerns
│   │   │   ├── config/                        # Runtime constants & environment variables
│   │   │   ├── database/                      # Drift database definition, DAOs & PowerSync connector
│   │   │   ├── encryption/                    # Android Keystore / iOS Keychain AES-256 engine
│   │   │   ├── router/                        # GoRouter configuration & biometric route guards
│   │   │   ├── theme/                         # Sunlight Ultra-Contrast & Material 3 systems
│   │   │   └── utils/                         # Geometry, formatting & date helpers
│   │   └── features/                          # Domain feature modules (Clean Architecture)
│   │       ├── auth_biometrics/              # Biometric lock & PIN fallback
│   │       ├── territory_catalog/            # Assigned territory list, filtering, offline cards
│   │       ├── field_map/                     # Mapbox/MapLibre offline tile renderer & START/STOP
│   │       ├── door_logging/                  # Rapid 1-handed status logger (Unvisited/NH/RV/DNC)
│   │       ├── return_visits/                 # Local encrypted RV CRM & Bible Study tracker
│   │       ├── service_timer/                 # Foreground notification timer & monthly S-4 reports
│   │       └── presence_voice/                # Realtime field presence & TTS voice navigation
│   └── pubspec.yaml
│
├── ozioma-desktop/                            # Dedicated Tauri 2.0 Desktop Suite (Win, Mac, Linux)
│   ├── src-tauri/                             # Rust Core Engine
│   │   ├── src/
│   │   │   ├── main.rs                        # Tauri entry point & command router
│   │   │   ├── gis/                           # Native GIS geometry (geo / geos vector operations)
│   │   │   │   ├── polygon_split.rs           # Topological polygon intersection & carving
│   │   │   │   └── street_snapping.rs         # Offline vector street vertex snapping
│   │   │   ├── printing/                      # Vector PDF S-13 card generation & OS print spooling
│   │   │   ├── keystore/                      # OS Keyring / Credential Manager integration
│   │   │   └── db/                            # Native SQLite / DuckDB congregation archive
│   │   ├── Cargo.toml
│   │   └── tauri.conf.json
│   ├── src/                                   # Desktop UI (React 19, TypeScript, Tailwind CSS)
│   │   ├── components/
│   │   │   ├── layout/                        # Tri-Pane Workspace (Navigator, GIS, Inspector)
│   │   │   ├── gis/                           # MapLibre GL JS / Deck.gl interactive vector canvas
│   │   │   ├── s13/                           # S-13 Territory Card preview & batch print modal
│   │   │   └── tables/                        # TanStack Table dense data grids & batch editors
│   │   ├── stores/                            # Zustand / TanStack Query state controllers
│   │   └── App.tsx
│   └── package.json
│
├── supabase/                                  # Cloud Infrastructure & Sync Definition
│   ├── migrations/                            # Normalized Postgres schema & RLS policies
│   ├── powersync_rules.yaml                   # PowerSync dynamic bucket replication rules
│   ├── edge-functions/                        # Push notifications, tile manifests, S-88 verification
│   └── tiles/                                 # PMTiles / MBTiles packaging scripts for Cloudflare R2
│
├── AUDIT_AND_STRATEGY.md                      # Comprehensive forensic audit & architecture blueprint
├── PHASES_TODO_SPRINTS.md                     # 14-sprint execution roadmap & task checklists
├── AGENTS.md                                  # Rules of engagement & engineering standards (This file)
└── CONTENT.md                                 # Theocratic domain dictionary, workflows & localization
```

---

## 3. State Management & Data Flow Standards

1. **Riverpod 2.x with Code Generation:**
   - Always use `@riverpod` annotations. Do not use legacy manual `ChangeNotifierProvider` or `StateProvider`.
   - Keep controllers lightweight: delegate business logic to domain services and persistence to DAOs.
   - Example:
     ```dart
     @riverpod
     class TerritoryListNotifier extends _$TerritoryListNotifier {
       @override
       Stream<List<TerritoryEntity>> build() {
         return ref.watch(territoryRepositoryProvider).watchCongregationTerritories();
       }
     }
     ```

2. **Reactive UI Binding:**
   - Use `AsyncValue.when()` to explicitly handle `loading`, `error`, and `data` states.
   - Never let an unhandled error crash the UI; display user-friendly error banners with retry triggers.

3. **Drift Queries:**
   - Always write queries using Drift's type-safe query builder. Avoid raw SQL strings in application code.
   - Expose queries as reactive `Stream<T>` via `.watch()` rather than one-time `.get()`.

---

## 4. Platform-Specific Implementation Rules

### 4.1 Mobile Field Platform Rules
- **Power Efficiency:** Location tracking must use `distanceFilter: 10` meters and pause when the device is stationary or app is backgrounded.
- **Sunlight Contrast:** Use `SunlightPalette` tokens (pure black `#000000`, high-vis yellow `#FFD600`, high-vis green `#00E676`).
- **Screen Real Estate:** Bottom navigation bar must have at most 5 primary destinations (Dashboard, Territories, RVs, Timer, Field Map).
- **Offline Assurance:** If an offline region is requested, ensure real vector tiles are spooled via `OfflineManager.loadStylePack` and `TileStore.loadTileRegion`.

### 4.2 Native Desktop Platform Rules (Tauri 2.0: Rust + React 19 / TypeScript)
- **Screen Organization:** Use a Tri-Pane layout (Territory Catalog Navigator on the left, high-precision GIS Map Canvas in the center, Assignment & Address Inspector on the right).
- **Keyboard Navigation:** Bind core operations to standard desktop keyboard shortcuts:
  - `Ctrl + N` / `Cmd + N`: Create new territory boundary.
  - `Ctrl + F` / `Cmd + F`: Focus territory search bar.
  - `Ctrl + P` / `Cmd + P`: Open S-13 Territory Card batch print dialog.
  - `Ctrl + S` / `Cmd + S`: Save polygon edits.
  - `Esc`: Cancel active polygon drawing or close inspector.
- **Precision GIS Editing (Rust Core):**
  - All heavy geometric calculations (topological intersection, polygon split, street vertex snapping, convex hull) must execute in the Rust core via the `geo` / `geos` crates and exposed to the React frontend via typed Tauri commands (`#[tauri::command]`).
  - Mouse-wheel zoom with smooth inertia; vector vertex snapping with visual snap guides ($\pm 5\text{px}$ threshold).
- **Native Document Printing:**
  - S-13 cards must be rendered as vector PDF documents using the Rust `printpdf` crate or Chromium headless printing, spooled directly to the OS print service with multi-up duplex layout (4 cards per A4 sheet).

---

## 5. Coding Standards & Git Protocol

1. **Code Formatting & Linting:**
   - **Mobile:** Strict adherence to `flutter_lints` rules; max line length: 120 characters; trailing commas required.
   - **Desktop Frontend:** ESLint + Prettier + TypeScript strict mode; zero `any` types.
   - **Desktop Backend (Rust):** Strict adherence to `clippy` and `rustfmt`.

2. **Git Commit Messages:**
   - Follow Conventional Commits: `feat(scope): description`, `fix(scope): description`, `refactor(scope): description`.
   - Examples:
     - `feat(desktop): implement S-13 vector PDF print spooler in Rust`
     - `feat(mobile): add PMTiles vector map loader from Cloudflare R2`
     - `fix(sync): unify drift database over powersync connection`
     - `refactor(mobile): rewrite door-logger for sunlight high contrast`

3. **Quality Gate:**
   - Before completing any agent task, run the applicable validation suite:
     - **Mobile Validation:**
       ```powershell
       cd ozioma-mobile
       dart run build_runner build --delete-conflicting-outputs
       flutter analyze
       flutter test
       ```
     - **Desktop Validation:**
       ```powershell
       cd ozioma-desktop
       cargo check --manifest-path src-tauri/Cargo.toml
       cargo test --manifest-path src-tauri/Cargo.toml
       pnpm lint
       pnpm test
       ```
   - Any commit that breaks static analysis or tests will be rejected.
