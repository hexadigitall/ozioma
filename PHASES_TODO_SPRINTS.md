# Ozioma: Systematic Development Phases, Sprints & Actionable Roadmap

**Platform:** Dual-Platform (Mobile & Native Desktop)  
**Methodology:** Agile / 2-Week Sprints with Continuous Offline Validation  
**Release Target:** Enterprise-Grade Field Ministry Platform  

---

## 1. Roadmap Overview & Strategic Phase Breakdown

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    OZIOMA DELIVERY ROADMAP                                       │
├──────────────┬──────────────┬──────────────┬──────────────┬──────────────┬───────────────────────┤
│   PHASE 0    │   PHASE 1    │   PHASE 2    │   PHASE 3    │   PHASE 4    │        PHASE 5        │
│ Toolchain &  │ Local-First  │ Mobile Field │ Cloud Sync & │ Native Desk  │ Hardening, Analytics  │
│ Architecture │ Core Engine  │ Experience   │ Presence     │ Admin Suite  │ & Production Launch   │
│ (Sprint 1)   │ (Sprints 2-3)│ (Sprints 4-6)│ (Sprints 7-8)│(Sprints 9-12)│    (Sprints 13-14)    │
└──────────────┴──────────────┴──────────────┴──────────────┴──────────────┴───────────────────────┘
```

---

## 2. Granular Phases, Sprints & Actionable Todo Lists

### Phase 0: Repository Stabilization & Toolchain Hygiene
**Goal:** Fix compilation blockers, purge mock/duplicate code, set up platform runners, and establish CI.

#### Sprint 1: Toolchain Normalization & Workspace Sanitization
- [x] **Repository Cleanup & Duplicate Purge**
  - [x] Delete redundant files: `lib/screens/shell_1.dart`, `lib/screens/territories_screen_1.dart`, `README_1.md`, `README_2.md`.
  - [x] Reconcile `territory_create_screen.dart` and `territory_mapper_screen.dart` into single feature module.
  - [x] Remove mock progress loops (`for (var i = 1; i <= 10; i++) ...`) across all map services.
- [x] **Dependency Harmonization (`pubspec.yaml`)**
  - [x] Add missing dependencies: `powersync`, `encrypt`, `crypto`, `sqlite3`.
  - [x] Clean up redundant SQLCipher declarations and ensure compatible binary bindings.
  - [x] Configure runtime configuration without hardcoded secrets.
- [x] **Platform Target Initialization**
  - [x] Generate native platforms: Android & iOS runners created and configured.
  - [x] Initialize `ozioma-desktop/` with Tauri 2.0 (Rust Core + React 19 / TypeScript).
  - [x] Establish Git repository baseline and initial architectural commit.

---

### Phase 1: Local-First Core Database & Security Engine
**Goal:** Build the unified PowerSync + Drift single database, implement hardware keystore encryption, and establish E2EE for householder privacy.

#### Sprint 2: Unified Database Engine & PowerSync Integration
- [x] **PowerSync Unified SQLite Engine**
  - [x] Configure unified `PowerSyncDatabase` (`ozioma_unified.db`) to eliminate dual-database desynchronization.
  - [x] Define canonical schema: `territories`, `addresses`, `return_visits_local` (Restricted PII), `service_logs`, `profiles`.
  - [x] Implement reactive streams using DAOs (`TerritoryDao`, `AddressDao`, `ReturnVisitDao`, `ServiceLogDao`) with Riverpod injection.
- [x] **Key Management & Hardware Keystore**
  - [x] Implement `SecureKeyManager` utilizing Android Keystore and iOS Keychain via `flutter_secure_storage`.
  - [x] Generate 256-bit AES master key on first launch; bind AES-256 cipher to key.
  - [x] Implement emergency duress key purge protocol and memory clearing on app pause.
  - [x] Automated unit and widget tests written and passing in CI baseline.

#### Sprint 3: Theocratic Privacy & Zero-Cloud PII Architecture
- [x] **Local-Only PII vs. Congregation Metadata Isolation**
  - [x] Separate sensitive householder data (`ReturnVisitsLocal`: name, phone, family notes) from cloud sync queue.
  - [x] Define anonymized sync schema: sync address status (`unvisited`, `not_at_home`, `rv_active`, `dnc`) without householder names.
  - [x] Implement Do-Not-Call (DNC) encrypted local registry with theocratic override protection.
- [x] **Biometric Gate & Lock Screen**
  - [x] Refactor `LockScreen` with exponential backoff, PIN fallback, and auto-lock on app backgrounding (30s threshold).
  - [x] Implement memory clearing for active decrypted buffers when app pauses.

---

### Phase 2: Mobile Field Experience & Sunlight Ergonomics
**Goal:** Deliver a robust, one-handed, sunlight-readable mobile UI for publishers working in high-glare, low-connectivity conditions.

#### Sprint 4: Sunlight Design System & Field Navigation Shell
- [x] **High-Contrast Sunlight Design System**
  - [x] Implement `SunlightTheme`: High-luminance palette (OLED black, crisp white, high-vis yellow, high-vis green).
  - [x] Enforce 48x48dp minimum touch targets on all interactive elements.
  - [x] Implement one-handed bottom-reach interaction zones for door logging.
- [x] **Navigation Shell Architecture**
  - [x] Build stateful bottom navigation: Dashboard, Territories, Return Visits, Timer, Resources.
  - [x] Ensure navigation stack is preserved when switching tabs in the field via `IndexedStack`.

#### Sprint 5: Door-to-Door Quick-Log & Cloudflare R2 Offline Vector Tile Delivery
- [x] **Door-to-Door Rapid Logger**
  - [x] Build swipe/tap address action bar: Unvisited $\rightarrow$ Not At Home $\rightarrow$ Return Visit $\rightarrow$ Do Not Call.
  - [x] Add haptic feedback and distinct audio confirmation ticks on status toggle.
  - [x] Implement undo toast with 5-second countdown to prevent accidental status changes.
- [x] **Cloudflare R2 / Supabase Storage Vector Tile Delivery**
  - [x] Deploy dedicated Supabase Storage bucket / Cloudflare R2 CDN for regional PMTiles/MBTiles archives (Port Harcourt, Lagos Metro, Calabar).
  - [x] Implement resumable HTTP range-request chunk downloader in mobile client with SHA-256 integrity verification.
  - [x] Render offline vector tiles locally via MapLibre/Mapbox without relying on cellular data in the field.
  - [x] Add thermal/battery optimization: throttle map frame rate to 30fps when stationary; pause rendering when sheet is expanded.

#### Sprint 6: Service Timer, Monthly Reporting & Return Visit CRM
- [x] **Reliable Field Service Timer**
  - [x] Implement foreground timer showing live elapsed time with sunlight ultra-contrast design.
  - [x] Support pausing, resuming, credit hours, and manual time adjustments (+15m, +30m, +1h).
  - [x] Save daily sessions automatically to Drift/PowerSync `ServiceLogs`.
- [x] **Return Visit & Bible Study Progression**
  - [x] Implement RV profile card: contact name, preferred call time, language, and visit notes.
  - [x] Integrate "Enjoy Life Forever!" curriculum tracker (Lessons 1-60, interactive progress bar & steppers).
  - [x] Implement S-4 monthly field service report generator with one-tap WhatsApp / SMS share to Group Overseer.

---

### Phase 3: Real-Time Sync, Presence & Congregation Cloud
**Goal:** Connect mobile clients to Supabase Postgres via PowerSync delta replication, provide real-time brother presence, and configure push notifications.

#### Sprint 7: PowerSync Cloud Sync & Dynamic Buckets
- [x] **PowerSync Backend Configuration**
  - [x] Deploy `powersync_rules.yaml` with dynamic parameter filtering on `profiles.congregation_id`.
  - [x] Configure upload batch handler in `SupabaseConnector` using Supabase v2 syntax with idempotent upserts.
  - [x] Test offline-to-online transition: simulate 50 offline door changes; verify conflict resolution (Last-Write-Wins via `updated_at`).
- [x] **Supabase Row-Level Security (RLS) Hardening**
  - [x] Enforce congregation isolation policies across `territories`, `addresses`, and `service_logs`.
  - [x] Restrict elder role permissions for assigning and archiving territories.

#### Sprint 8: Service Group Presence & Voice Guidance
- [x] **Privacy-Preserving Field Presence**
  - [x] Connect `PresenceService` to live Supabase Realtime Channels scoped to active territory ID.
  - [x] Enforce auto-expiration: location broadcast automatically terminates at 12:00 PM or after 4 hours.
  - [x] Display brother pins on map with distance indicators and randomized privacy offsets ($\pm 15$m).
- [x] **Voice Guidance Engine**
  - [x] Integrate offline Text-To-Speech (`flutter_tts`) for navigating to territory START/STOP pins.
  - [x] Implement proximity triggers: "200 meters to Territory #14 START point."

---

### Phase 4: Dedicated Native Desktop Application (Tauri 2.0: Rust + React 19 / TypeScript)
**Goal:** Build a dedicated high-performance native desktop workspace (Windows, macOS, Linux) engineered with Tauri 2.0, utilizing a Rust GIS core and a dense React 19 / TypeScript UI for Territory Overseers, Service Overseers, and Secretaries.

#### Sprint 9: Tauri 2.0 Workspace Architecture & Multi-Pane Layout
- [x] **Tauri 2.0 & Rust Core Initialization**
  - [x] Initialize `ozioma-desktop` using Tauri 2.0 (`tauri-build`, `tauri-plugin-sql`, `tauri-plugin-fs`).
  - [x] Configure React 19 + TypeScript + Tailwind CSS frontend shell (built & verified with Vite).
- [x] **Desktop Tri-Pane Layout**
  - [x] Left pane: Congregation territory inventory with multi-column sorting, filter tags, and status counters.
  - [x] Center pane: High-precision GIS map canvas supporting mouse-wheel zoom, pan, and coordinate display.
  - [x] Right pane: Deep territory inspector, publisher assignment history, and address registry.
- [x] **Desktop Shell & Native Enhancements**
  - [x] Implement desktop menu bar (File, Edit, Territories, Reports, View, Window).
  - [x] Implement comprehensive keyboard shortcuts (Ctrl+N: New Territory, Ctrl+F: Search, Ctrl+P: Print, Space: Pan Map).
  - [x] Support window resizing, high-DPI scaling, and S-13 vector PDF card preview modal.

#### Sprint 10: Precision GIS Cartography & Boundary Drawing Tools (Rust Core)
- [x] **Rust-Powered Vector Geometry Tools (`geo` / `geos`)**
  - [x] Expose native geometry operations via Tauri commands: polygon area, centroid calculation, topological intersection.
  - [x] Polygon drawing mode with click-to-place vertex and vertex snapping ($\pm 5\text{px}$ visual guides).
  - [x] Vertex manipulation: click-and-drag existing polygon boundaries to adjust for new real estate developments.
  - [x] Territory splitting tool: draw an intersection line across a polygon to automatically carve it into two sub-territories (#14A and #14B).
- [x] **Boundary Validation & Conflict Engine**
  - [x] Detect overlapping polygons between adjacent territories.
  - [x] Calculate exact boundary area in hectares and estimated residential door count.

#### Sprint 11: S-13 Territory Card Engine & Native Print Spooling
- [x] **Official S-13 Form Generator in Rust**
  - [x] Render official S-13 (Territory Assignment Card) vector PDF layouts using Rust `printpdf` or headless print driver.
  - [x] Embed high-resolution vector territory boundary mini-map on front of card.
  - [x] List street bounds, boundary streets, and QR code for instant mobile publisher scan.
- [x] **Batch Print Spooler**
  - [x] Multi-up printing layout (4 cards per A4 sheet, front-and-back duplex orientation).
  - [x] Spool directly to OS native print dialogs (Windows GDI/Print Spooler, macOS CUPS).

#### Sprint 12: Bulk Data Operations & Congregation Importer
- [x] **Excel / CSV Master Importer**
  - [x] High-speed streaming CSV/XLSX parser in Rust (via `calamine` crate) for master street and address lists.
  - [x] Fuzzy address matching and geocoding pipeline.
- [x] **Local Offline DuckDB / SQLite Archive & Keyring**
  - [x] Secure local encryption keys via OS Keyring / Credential Manager.
  - [x] Enable local encrypted database backups to USB / external drives for offline disaster recovery.
  - [x] Export congregation records to KML/GeoJSON for branch office reporting.

---

### Phase 5: Enterprise Hardening, Circuit Overseer Analytics & Launch
**Goal:** Deliver circuit-level analytics, rigorous end-to-end testing, golden UI tests, and release pipelines.

#### Sprint 13: Circuit Overseer (CO) & Annual Analytics Suite
- [ ] **Territory Saturation & Coverage Analytics**
  - [ ] Visual heatmap of congregation territory: identify territories unworked for >6 months.
  - [ ] Pioneer hour pacing and assignment equity dashboards.
- [ ] **Annual S-8 Congregation Report Generator**
  - [ ] Generate comprehensive territory analysis summaries for the visiting Circuit Overseer.

#### Sprint 14: Quality Assurance, Security Penetration & Store Deployment
- [ ] **Comprehensive Test Suites**
  - [ ] Unit tests for Drift DAOs, sync conflict logic, and geometry algorithms (>85% coverage).
  - [ ] Golden widget tests for Sunlight Mode on mobile and Multi-Pane layout on Desktop.
  - [ ] Chaos testing: network disconnects during 1000-record batch writes.
- [ ] **Release Packaging & Signing**
  - [ ] Android App Bundle (AAB) signed for Google Play Store.
  - [ ] iOS IPA signed for Apple TestFlight / App Store.
  - [ ] Windows MSIX package and macOS `.dmg` signed for native desktop installation.

---

## 3. Definition of Done (DoD)

A user story or sprint task is considered **Done** only when all the following criteria are verified:

1. **Compilation & Static Analysis:** Zero warnings or errors in `flutter analyze` and `dart analyze`.
2. **Offline-First Integrity:** Feature functions 100% without active cellular or internet connection.
3. **Reactive Single DB:** All data mutations execute through the unified PowerSync-Drift database layer.
4. **Sunlight & Target Compliance:** Mobile touch targets $\ge 48\times 48\text{dp}$; high-contrast text passes WCAG AAA (7:1 contrast ratio).
5. **Theocratic Privacy:** No householder Personally Identifiable Information (PII) is emitted to cloud logs or unencrypted cloud tables.
6. **Automated Testing:** Unit/integration tests written and passing in CI pipeline.
7. **Desktop Paradigm Invariant:** Desktop views must utilize multi-pane, dense data, and keyboard shortcuts; stretching mobile views is strictly rejected.
