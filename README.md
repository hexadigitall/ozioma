# Ozioma (Ọzịọma)

> **Worldwide Theocratic Field Ministry & Congregation Administration Platform**  
> *Dual-Platform Architecture: Flutter 3.24+ Mobile & Tauri 2.0 (Rust + React 19) Native Desktop*

[![Mobile Analysis](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter&logoColor=white)](#)
[![Desktop Engine](https://img.shields.io/badge/Tauri-2.0_(Rust_+_React_19)-FFC131?logo=tauri&logoColor=black)](#)
[![Zero-Cloud PII](https://img.shields.io/badge/Security-Hardware_AES--256--GCM-00E676)](#)
[![Sync Engine](https://img.shields.io/badge/Offline--First-PowerSync_+_SQLite-00B4D8)](#)
[![License](https://img.shields.io/badge/License-Proprietary-slate)](#)

---

## 1. Overview & Vision

**Ozioma** (*"Good News"* in Igbo) is an enterprise-grade, offline-first theocratic platform engineered for Jehovah's Witnesses operating across 240+ lands worldwide. 

The platform replaces fragile paper territory maps (S-13) and manual service reporting with a dual-platform paradigm:
1. **Mobile Platform (Flutter 3.24+ / Dart):** Engineered for the publisher walking door-to-door in direct sunlight. Features one-handed rapid status logging, 700-nit ultra-contrast Sunlight mode, persistent background field timers, encrypted return visit management, and offline vector map tile caching from Cloudflare R2.
2. **Native Desktop Platform (Tauri 2.0: Rust Core + React 19 / TypeScript):** An administrative power-tool built for Territory Overseers, Service Overseers, and Congregation Secretaries. Features dense tri-pane data grids, mouse-precision GIS polygon boundary editing with topological snapping, and native multi-up duplex vector PDF printing for official S-13 territory assignment cards.

---

## 2. Architectural Invariants & Prime Directives

All platform development strictly adheres to the canonical standards defined in [AGENTS.md](file:///D:/projects/ozioma/AGENTS.md):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             OZIOMA ARCHITECTURE                             │
├──────────────────────────────────────┬──────────────────────────────────────┤
│       MOBILE CLIENT (Flutter 3.24+)   │   NATIVE DESKTOP SUITE (Tauri 2.0)   │
│  • Touch-first & one-handed reach    │  • Dense tri-pane administrative UI  │
│  • Sunlight Ultra-Contrast (WCAG AAA)│  • Native Rust GIS geometry (geo)    │
│  • 48x48dp minimum touch bounds      │  • Multi-column TanStack data tables │
│  • Hardware Keystore AES-256-GCM     │  • Native OS vector S-13 PDF spooler │
├──────────────────────────────────────┴──────────────────────────────────────┤
│                   UNIFIED OFFLINE-FIRST PERSISTENCE LAYER                   │
│  • Single local SQLite database file per platform (ozioma_unified.db)       │
│  • PowerSync delta sync engine with dynamic client bucket replication       │
│  • Cloudflare R2 / Supabase Storage CDN worldwide PMTiles vector tiles      │
├─────────────────────────────────────────────────────────────────────────────┤
│                    ZERO-CLOUD PII THEOCRATIC PRIVACY                        │
│  • Strict segregation of local householder PII from cloud replication      │
│  • Compliant with global privacy laws (GDPR, CCPA, LGPD, NDPA, APPI, POPIA) │
│  • Emergency duress key purge protocol (9999) destroying local cipher key   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Invariant Highlights
- **No Stretched Mobile UIs:** Mobile and Desktop platforms are independently maintained. The desktop app is never a stretched mobile port; it is built with Tauri 2.0, utilizing native Rust commands for heavy GIS cartography.
- **Single Database File:** Drift is instantiated solely through `PowerSyncDatabase.driftConnection`. Never run dual databases.
- **Zero Cloud PII:** Householder names, phone numbers, and visit notes remain strictly on-device under AES-256-GCM encryption. Only anonymized territory boundary GeoJSON and address visit statuses (`unvisited`, `not_at_home`, `return_visit`, `do_not_call`) synchronize to the cloud.

---

## 3. Directory Layout

```
ozioma/
├── ozioma-mobile/                             # Flutter 3.24+ Mobile Client (Android & iOS)
│   ├── lib/
│   │   ├── app.dart                           # Root app & sunlight theme router
│   │   ├── bootstrap.dart                     # Async initialization (Keystore, PowerSync, Drift)
│   │   ├── core/
│   │   │   ├── auth/                          # BiometricAuthService, PIN gate, duress purge
│   │   │   ├── database/                      # Unified PowerSync manager, Drift DAOs & schema
│   │   │   ├── encryption/                    # SecureKeyManager (AES-256 hardware keystore)
│   │   │   └── theme/                         # SunlightPalette & SunlightTheme (WCAG AAA)
│   │   ├── features/
│   │   │   ├── door_logging/                  # Rapid 1-handed action logger & walking sheet
│   │   │   └── return_visits/                 # Local encrypted RV CRM & "Enjoy Life Forever!" tracker
│   │   ├── screens/                           # Core screens (Dashboard, Territories, Field Map, Timer)
│   │   └── services/                          # Offline PMTiles downloader, Presence, Voice guidance
│   ├── test/                                  # Comprehensive automated unit & widget test suite
│   └── pubspec.yaml
│
├── ozioma-desktop/                            # Dedicated Tauri 2.0 Desktop Application
│   ├── src-tauri/                             # Rust Core Engine
│   │   ├── src/
│   │   │   ├── main.rs                        # Tauri command router & app entry
│   │   │   ├── gis/                           # Native GIS geometry (geo / geos vector operations)
│   │   │   ├── printing/                      # Vector PDF S-13 territory card print spooler
│   │   │   └── keystore/                      # OS Credential Manager / Keyring integration
│   │   └── Cargo.toml
│   ├── src/                                   # Desktop Frontend (React 19, TypeScript, Tailwind)
│   │   ├── components/layout/                 # Tri-Pane Workspace (Catalog, GIS Canvas, Inspector)
│   │   ├── components/s13/                    # Official S-13 vector card preview modal
│   │   ├── components/tables/                 # TanStack Table dense data grids
│   │   └── stores/                            # Zustand reactive territory & GIS store
│   └── package.json
│
├── supabase/                                  # Backend Cloud Infrastructure
│   ├── schema.sql                             # Normalized PostgreSQL schema (Zero-Cloud PII)
│   ├── powersync_rules.yaml                   # PowerSync parameter-filtered dynamic buckets
│   └── tiles/                                 # PMTiles / MBTiles Cloudflare R2 packaging scripts
│
├── AGENTS.md                                  # Autonomous engineering invariants & code rules
├── AUDIT_AND_STRATEGY.md                      # Comprehensive codebase audit & architectural blueprint
├── CONTENT.md                                 # Theocratic domain dictionary, S-13/S-4 specs & localization
└── PHASES_TODO_SPRINTS.md                     # 14-sprint execution roadmap & progress tracking
```

---

## 4. Key Features

### Mobile Client (Field Ministry)
- **Ultra-Contrast Sunlight Theme:** Designed for 700-nit direct equatorial sunlight with OLED pitch black (`#000000`), crisp white, and high-visibility yellow/green accents meeting WCAG AAA.
- **One-Handed Door-to-Door Logger:** Swipe and tap status bar (`Unvisited` $\rightarrow$ `NH` $\rightarrow$ `RV` $\rightarrow$ `DNC`) with haptic confirmation and a 5-second undo toast.
- **Worldwide Offline Vector Tiles:** Pre-sliced PMTiles distributed via Cloudflare R2 / Supabase CDN with chunked resumable downloads.
- **Field Service Timer & S-4 Reporting:** Live elapsed time, credit hour adjustments, daily session storage, and one-tap WhatsApp / SMS report sharing to Group Overseers.
- **"Enjoy Life Forever!" Tracker:** Tracks progression across all 60 interactive lessons of the primary study curriculum.
- **Theocratic Do-Not-Call (DNC) Gate:** Instantly purges local householder notes and locks the address against accidental contact.
- **Emergency Duress Purge:** Entering PIN `9999` permanently deletes the local encryption key, protecting sensitive records.

### Native Desktop Suite (Congregation Administration)
- **Tri-Pane Administrative Workspace:** Dense inventory table on the left, interactive MapLibre vector GIS canvas in the center, and assignment/address inspector on the right.
- **Native Vector GIS Cartography (Rust Core):** Precision vertex snapping, polygon area calculations, and topological intersection carving executed in native Rust via `geo`.
- **Official S-13 Territory Card Engine:** Generates high-resolution vector PDF territory assignment cards with mini-maps, street bounds, and QR codes for multi-up duplex printing.
- **Keyboard Power Shortcuts:** `Ctrl+N` (New Territory), `Ctrl+F` (Search), `Ctrl+P` (S-13 Print), `Ctrl+S` (Save GIS Edits), `Esc` (Cancel Tool).

---

## 5. Development & Getting Started

### Prerequisites
- **Flutter SDK:** $\ge 3.24.0$ with Dart SDK $\ge 3.3.0$
- **Node.js:** $\ge 20.0.0$ (v24 LTS recommended)
- **Rust Toolchain:** $\ge 1.78.0$ (with `cargo` and Tauri CLI `cargo install tauri-cli --version "^2.0.0"`)

### Mobile Setup
```powershell
# Navigate to mobile project
cd ozioma-mobile

# Install Flutter dependencies
flutter pub get

# Run static analysis
dart analyze lib

# Run automated test suite
flutter test

# Launch mobile application
flutter run
```

### Desktop Setup
```powershell
# Navigate to desktop project
cd ozioma-desktop

# Install frontend dependencies
npm install

# Verify TypeScript compilation and Vite build
npm run build

# Launch Tauri 2.0 native desktop application
npm run tauri dev
```

---

## 6. Theocratic Localization & Terminology

Ozioma supports worldwide field ministry across major global preaching languages:

| English | Spanish | Portuguese | French | German | Japanese | Swahili | Tagalog | Yoruba | Igbo | Pidgin |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Field Ministry** | Ministerio del campo | Ministério de campo | Ministère du champ | Predigtdienst | 野外奉仕 | Huduma ya shambani | Larangan | Iṣẹ́ Ìwàásù | Ozi Ubi | Field Service |
| **Good News** | Buenas noticias | Boas novas | Bonne nouvelle | Gute Botschaft | 良い知らせ | Habari njema | Mabuting balita | Ìhìn Rere | Oziọma | Good News |
| **Territory** | Territorio | Território | Territoire | Gebiet | 区域 | Eneo | Teritoryo | Ìpínlẹ̀ Ìwàásù | Ókè-Ala | Territory |
| **Return Visit** | Revisita | Revisita | Nouvelle visite | Rückbesuch | 再訪問 | Ziara ya kurudia | Pagdalaw-muli | Ìpadàbẹ̀wò | Nletaghachi | Return Visit |
| **Bible Study** | Curso bíblico | Estudo bíblico | Cours biblique | Bibelstudium | 聖書研究 | Funzo la Biblia | Pag-aaral | Ìkẹ́kọ̀ọ́ Bíbélì | Ọmụmụ Baịbụl | Bible Study |
| **Not At Home** | No en casa | Não estava | Absent | Nicht angetroffen | 不在 | Hakuwepo | Walang tao | Kò Sí Nílé | Anọghị n'Ụlọ | Dem No Dey House |
| **Do Not Call** | No llamar | Não visitar | Ne pas visiter | Nicht vorsprechen | 訪問拒否 | Usirudi tena | Huwag dadalawin | Ẹ Má Ṣe Wá Síbẹ̀ | Akpọnala | Make You No Call |

---

## 7. Quality Gate & Continuous Integration

Every commit must satisfy the three non-negotiable verification gates:

1. **Mobile Test Coverage:** $\ge 85\%$ automated unit and widget test pass rate (`flutter test`).
2. **Mobile Linting:** Zero warnings and zero hints from `dart analyze lib`.
3. **Desktop Validation:** TypeScript compiles with strict mode (`npm run build`).

---

## 8. Canonical Documentation References

- **[AGENTS.md](file:///D:/projects/ozioma/AGENTS.md):** Rules of engagement, prime directives, and code invariants.
- **[AUDIT_AND_STRATEGY.md](file:///D:/projects/ozioma/AUDIT_AND_STRATEGY.md):** Detailed architectural forensic audit and system blueprint.
- **[CONTENT.md](file:///D:/projects/ozioma/CONTENT.md):** Theocratic domain reference, S-13/S-4 specifications, and localization dictionary.
- **[PHASES_TODO_SPRINTS.md](file:///D:/projects/ozioma/PHASES_TODO_SPRINTS.md):** 14-sprint roadmap across all phases.
