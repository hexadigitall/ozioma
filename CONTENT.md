# CONTENT.md — Domain Bible, Content Model & Theocratic Single Source of Truth

**Platform:** Ozioma (Dual-Platform Mobile & Native Desktop)  
**Classification:** Canonical Theocratic Domain Reference & Content Architecture  
**Target Context:** Worldwide Field Ministry & Congregation Administration across 240+ Lands and Territories (Global Scale with Zero-Cloud PII Invariants)  

---

## 1. Theocratic Hierarchy & Organizational Structure

Ozioma models the exact administrative and functional structure of a Christian congregation of Jehovah's Witnesses:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                             BRANCH OFFICE                               │
│              (Oversees country / regional theocratic activity)          │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            CIRCUIT OVERSEER                             │
│       (Traveling minister visiting congregations every 6 months)        │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      CONGREGATION BODY OF ELDERS                        │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │                  CONGREGATION SERVICE COMMITTEE                     │ │
│ │  • Coordinator of the Body of Elders (COBE)                         │ │
│ │  • Congregation Secretary                                           │ │
│ │  • Service Overseer                                                 │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                    │                                    │
│ ┌──────────────────────────────────┴──────────────────────────────────┐ │
│ │ TERRITORY SERVANT (Ministerial Servant managing territory inventory)│ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       FIELD SERVICE GROUPS                              │
│       (Led by Group Overseer & Assistant; organized by locality)        │
├──────────────────────────┬──────────────────────────┬───────────────────┤
│    REGULAR PIONEERS      │    AUXILIARY PIONEERS    │    PUBLISHERS     │
│  (50 hrs/mo commitment)  │ (15 or 30 hrs/mo target) │  (Active members) │
└──────────────────────────┴──────────────────────────┴───────────────────┘
```

### 1.1 Theocratic Roles & System Permissions

| Role | System Scope | Core Responsibilities in Ozioma |
| :--- | :--- | :--- |
| **Publisher** | Mobile App | Works assigned territories; logs house-to-house statuses; manages personal return visits; tracks daily timer; submits monthly S-4 service report. |
| **Auxiliary Pioneer** | Mobile App | All publisher capabilities + paces hours towards 15 or 30-hour monthly goals with daily hourly projection meters. |
| **Regular Pioneer** | Mobile App | All publisher capabilities + paces hours towards 50-hour monthly (600-hour annual) requirement; tracks Bible study curriculum progression; logs credit hours. |
| **Group Overseer** | Mobile / Desktop | Monitors group field service activity; receives group monthly reports; assists group members with territory coverage. |
| **Territory Servant** | Native Desktop | Master manager of all congregation territory boundaries, maps, assignments, due dates, S-13 cards, and territory rebalancing. |
| **Service Overseer** | Native Desktop | Oversees territory coverage frequency, annual campaign strategies, and reviews legal Do-Not-Call (DNC) records. |
| **Secretary** | Native Desktop | Compiles aggregate monthly S-4 reports for the congregation; submits electronic report to Branch Office via jw.org portal. |
| **Circuit Overseer** | Native Desktop | Audits congregation territory saturation (S-8 form) during bi-annual pastoral visits. |

---

## 2. Territory Management Domain Model

### 2.1 Territory Taxonomy

```
                           TERRITORY TYPES
                                  │
    ┌─────────────────┬───────────┴───────────┬─────────────────┐
    ▼                 ▼                       ▼                 ▼
Residential      Commercial /           Rural / Search      Campaign /
Door-to-Door      Business                  Work             Special
(Standard homes   (Shops, offices,        (Sparse villages,   (Memorial, convention
 & compounds)      markets, plazas)        unpaved tracks)     invitation drives)
```

1. **Residential (Standard Door-to-Door):**
   - Urban and suburban residential streets, multi-family compounds, apartment blocks, and gated estates.
   - Primary challenge: High walls, gates, and intercoms in urban centers (e.g., GRA Phase 2 Port Harcourt, Lekki Lagos).
2. **Commercial / Business:**
   - Open-air markets, shopping centers, office complexes, and high-density commercial strips.
   - Specialized logging: Store name, floor/shop number, manager/owner contact time.
3. **Rural / Search Work:**
   - Outlying rural communities and scattered settlements where physical street addresses do not exist.
   - Navigation relies heavily on GPS coordinates, landmarks, village head compounds, and river access points.
4. **Campaign / Special Territories:**
   - Temporary subdivision of territories used during global invitation distribution (Memorial season, Regional Conventions). High focus on rapid coverage of all residences within 3–4 weeks.

### 2.2 The Territory Lifecycle State Machine

```
              ┌──────────────────────────┐
              │        AVAILABLE         │
              │  (Ready for assignment)  │
              └─────────────┬────────────┘
                            │ Elder assigns territory (due date: +4 months)
                            ▼
              ┌──────────────────────────┐
              │         ASSIGNED         │
              │ (PowerSync pushes to mob)│
              └─────────────┬────────────┘
                            │ Publisher works doors & logs statuses
                            ▼
              ┌──────────────────────────┐
              │       IN PROGRESS        │
              │  (Progress: 1% to 99%)   │
              └─────────────┬────────────┘
                            │ All addresses visited & worked thoroughly
                            ▼
              ┌──────────────────────────┐
              │        COMPLETED         │
              │ (Returned to overseer)   │
              └─────────────┬────────────┘
                            │ Checked in by Territory Servant
                            ▼
              ┌──────────────────────────┐
              │         ARCHIVED         │
              │(Cool-down period: 2 mos) │
              └──────────────────────────┘
```

### 2.3 The Official S-13 Territory Assignment Card Specification
The **S-13** is the standard theocratic form used worldwide for territory record-keeping. The native desktop version must render exact, printable vector S-13 cards:

#### S-13 Card Structure (Standard Front & Back):
- **Front of Card:**
  - Congregation Name & Circuit
  - Territory Number (e.g., `#14`)
  - Territory Name / Neighborhood (e.g., `Oakwood, Port Harcourt`)
  - High-Resolution Vector Boundary Map (centered on territory, showing perimeter streets)
  - Boundary Description (North, South, East, West border streets)
  - QR Code (encodes encrypted token for instant import into publisher's Ozioma mobile app)
- **Back of Card (Assignment Log Table):**
  - Columns:
    1. Assigned To (Publisher Name)
    2. Date Assigned (DD-MMM-YYYY)
    3. Date Completed (DD-MMM-YYYY)
    4. Notes / Specific Instructions (e.g., "Do not visit compounds on Sunday before 11:00 AM")

---

## 3. Field Ministry Activity & Status Logging

### 3.1 Door-to-Door Address Statuses

When working door-to-door, publishers encounter five fundamental statuses:

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                          DOOR-TO-DOOR STATUS SYSTEM                            │
├─────────────────┬───────────┬──────────────────────────────────────────────────┤
│ STATUS          │ COLOR     │ DEFINITION & FIELD PROTOCOL                      │
├─────────────────┼───────────┼──────────────────────────────────────────────────┤
│ Unvisited       │ Slate 500 │ Default state. House has not yet been approached │
│                 │ (#64748B) │ during the current working cycle.                │
├─────────────────┼───────────┼──────────────────────────────────────────────────┤
│ Not At Home     │ Amber 500 │ No resident answered the gate/door. Must be      │
│ (NH)            │ (#F59E0B) │ re-approached at a different time/day.           │
├─────────────────┼───────────┼──────────────────────────────────────────────────┤
│ Return Visit    │ Green 500 │ Resident demonstrated spiritual interest.        │
│ (RV)            │ (#10B981) │ Personal follow-up record created.               │
├─────────────────┼───────────┼──────────────────────────────────────────────────┤
│ Do Not Call     │ Red 600   │ Resident explicitly requested not to be visited. │
│ (DNC)           │ (#DC2626) │ LOCKED. Must not be approached under any state.  │
├─────────────────┼───────────┼──────────────────────────────────────────────────┤
│ Inaccessible /  │ Purple 500│ Demolished building, vacant plot, aggressive     │
│ Vacant          │ (#8B5CF6) │ dogs, or permanently locked gate.                │
└─────────────────┴───────────┴──────────────────────────────────────────────────┘
```

### 3.2 The Do-Not-Call (DNC) Theocratic & Legal Protocol

**Mandatory Rule:** In accordance with theocratic order and international data privacy laws:
1. When a resident states "Do not come back here" or displays hostile opposition:
   - The publisher flags the address as **Do Not Call (DNC)**.
   - The address marker turns **Bold Red** on the mobile map and is immediately locked.
   - No personal notes or names of the resident may be stored. Only the physical house number and date are logged.
2. **Congregation Sync:**
   - DNC flags synchronize instantly to the congregation database so no other publisher knocks on the gate.
3. **Annual Elder Review:**
   - Under the direction of the Service Overseer, elders periodically review the DNC list (usually once every 1–2 years) to determine if residents have relocated or if a discreet pastoral inquiry should be made.

---

## 4. Return Visits & The "Enjoy Life Forever!" Bible Study Curriculum

When spiritual interest is found, a **Return Visit (RV)** record is established. If the person agrees to a systematic discussion of the Bible, it is classified as a **Bible Study**.

### 4.1 Curriculum Structure: *"Enjoy Life Forever!"*
Ozioma incorporates the exact structured syllabus of the primary teaching publication:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│              "ENJOY LIFE FOREVER!" — AN INTERACTIVE BIBLE COURSE                │
├──────────────────────────────┬──────────────────┬───────────────────────────────┤
│ SECTION                      │ LESSON RANGE     │ PRIMARY THEME                 │
├──────────────────────────────┼──────────────────┼───────────────────────────────┤
│ Section 1: Intro to the Bible│ Lessons 01 to 12 │ The Bible, God's Name, Prayer │
│ Section 2: God's Promises    │ Lessons 13 to 33 │ Jesus, Kingdom, Resurrection  │
│ Section 3: Christian Living  │ Lessons 34 to 47 │ Worship, Family, Integrity    │
│ Section 4: Deep Truths       │ Lessons 48 to 60 │ Dedicated Service, Baptism    │
└──────────────────────────────┴──────────────────┴───────────────────────────────┘
```

### 4.2 Return Visit Profile Data Contract (Restricted Local PII)

```yaml
ReturnVisitEntity:
  id: "uuid-v4"
  address_id: "uuid-v4"
  householder_name: "Encrypted(String)"         # Local Keystore AES-256
  phone_number: "Encrypted(String)"             # Local Keystore AES-256
  preferred_contact_time: "Morning / Saturday"
  language_preference: "Igbo"
  current_lesson: 3                             # Lesson number in Enjoy Life Forever
  is_active_bible_study: true
  visit_history:
    - visit_date: "2026-11-15T09:30:00Z"
      scripture_read: "Revelation 21:3, 4"
      publication_placed: "Enjoy Life Forever! Brochure"
      next_question: "Why does God allow suffering?"
      notes: "Encrypted(String)"                # Local Keystore AES-256
```

---

## 5. Field Service Reporting Standards (Form S-4)

At the end of each calendar month, every publisher submits a field service report (**S-4**).

### 5.1 Monthly Reporting Metrics

| Metric | Publishers | Auxiliary Pioneers | Regular Pioneers | Calculation / Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Active Checkmark** | Yes | Yes | Yes | Confirms participation in ministry during the month. |
| **Hours** | Optional / Encouraged | Required (15 or 30 hrs) | Required (50 hrs) | Cumulative time spent in actual preaching activity. |
| **Bible Studies** | Required | Required | Required | Count of *different* individuals studied with in the month. |
| **Credit Hours** | N/A | N/A | Approved only | Authorized credit for attending schools or disaster relief. |

### 5.2 Pioneer Pacing Algorithm
For Regular Pioneers, Ozioma calculates daily target pacing:

$$\text{Daily Target (hrs)} = \frac{50 - \text{Hours Completed to Date}}{\text{Days Remaining in Month}}$$

---

## 6. Worldwide Multilingual Theocratic Dictionary & Localization

Field ministry across 240+ lands is intrinsically multilingual. Ozioma provides unified data modeling and theocratic localization across major global preaching languages:

### 6.1 Core Global Preaching Languages

```
┌──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┐
│ English              │ Spanish (Español)    │ Portuguese (Português│ French (Français)    │
├──────────────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Field Ministry       │ Ministerio del campo │ Ministério de campo  │ Ministère du champ   │
│ Good News            │ Buenas noticias      │ Boas novas           │ Bonne nouvelle       │
│ Territory            │ Territorio           │ Território           │ Territoire           │
│ Return Visit         │ Revisita             │ Revisita             │ Nouvelle visite      │
│ Bible Study          │ Curso bíblico        │ Estudo bíblico       │ Cours biblique       │
│ Not At Home          │ No en casa           │ Não estava           │ Absent               │
│ Do Not Call          │ No llamar            │ Não visitar          │ Ne pas visiter       │
│ Publisher            │ Publicador           │ Publicador           │ Proclamateur         │
│ Regular Pioneer      │ Precursor regular    │ Pioneiro regular     │ Pionnier permanent   │
│ Service Overseer     │ Superintendente serv.│ Sup. de serviço      │ Surv. de service     │
│ Body of Elders       │ Cuerpo de ancianos   │ Corpo de anciãos     │ Collège d'anciens    │
│ Enjoy Life Forever!  │ ¡Disfrute de la vida!│ Viva Feliz Para Semp.│ Vivez pour toujours !│
└──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┘
```

```
┌──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┐
│ German (Deutsch)     │ Tagalog              │ Swahili (Kiswahili)  │ Japanese (日本語)    │
├──────────────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Predigtdienst        │ Larangan ng minister.│ Huduma ya shambani   │ 野外奉仕             │
│ Gute Botschaft       │ Mabuting balita      │ Habari njema         │ 良い知らせ           │
│ Gebiet               │ Teritoryo            │ Eneo                 │ 区域                 │
│ Rückbesuch           │ Pagdalaw-muli        │ Ziara ya kurudia     │ 再訪問               │
│ Bibelstudium         │ Pag-aaral sa Bibliya │ Funzo la Biblia      │ 聖書研究             │
│ Nicht angetroffen    │ Walang tao           │ Hakuwepo             │ 不在                 │
│ Nicht vorsprechen    │ Huwag dadalawin      │ Usirudi tena         │ 訪問拒否             │
│ Verkündiger          │ Mamamahayag          │ Mhubiri              │ 伝道者               │
│ Allgemeiner Pionier  │ Regular pioneer      │ Painia wa kawaida    │ 開拓者               │
│ Dienstaufseher       │ Tagapangasiwa sa pag.│ Mwangalizi wa huduma │ 奉仕監督             │
│ Ältestenschaft       │ Lupon ng matatanda   │ Baraza la wazee      │ 長老団               │
│ Glücklich – für imm. │ Masisiyahan Ka Magpal│ Furahia Maisha Milele│ いつまでも幸せに！   │
└──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┘
```

```
┌──────────────────────┬──────────────────────┬──────────────────────┬──────────────────────┐
│ Nigerian Pidgin      │ Yoruba               │ Igbo                 │ Hausa                │
├──────────────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Field Service        │ Iṣẹ́ Ìwàásù           │ Ozi Ubi              │ Wa'azi               │
│ Good News            │ Ìhìn Rere            │ Oziọma               │ Biyayyar Albishir    │
│ Territory            │ Ìpínlẹ̀ Ìwàásù        │ Ókè-Ala / Teritori   │ Yanki                │
│ Return Visit         │ Ìpadàbẹ̀wò           │ Nletaghachi          │ Ziyara               │
│ Bible Study          │ Ìkẹ́kọ̀ọ́ Bíbélì        │ Ọmụmụ Baịbụl          │ Nazarin Littafi Mai M│
│ Dem No Dey House     │ Kò Sí Nílé           │ Anọghị n'Ụlọ         │ Ba a gida            │
│ Make You No Call     │ Ẹ Má Ṣe Wá Síbẹ̀      │ Akpọnala / Abịala    │ Kada a sake zuwa     │
│ Publisher            │ Akéde                │ Onye Nkwusa          │ Mai shela            │
│ Pioneer              │ Aṣáájú-Ọ̀nà           │ Onye Ọsụ Ụzọ         │ Majagaba             │
│ Service Overseer     │ Alábòójútó Iṣẹ́        │ Onye Nlekọta Ozi     │ Manajan Wa'azi       │
│ Body of Elders       │ Ìgbìmọ̀ Àwọn Alàgbà    │ Òtù Ndị Okenye       │ Majalisar Dattijai   │
│ Enjoy Life Forever!  │ Gbádùn Ayé Rẹ Títí   │ Nwee Obi Ụtọ Ruo Ebi.│ Ji Daɗin Rai Har Ab. │
└──────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┘
```

---

## 7. Field Security & Discretion Protocols

1. **Sunlight & Screen Discretion:**
   Publishers frequently work in areas where displaying expensive smartphones attracts unwanted attention. The app features a **Discreet / Stealth Lock**: tapping the top bar twice turns the screen into a simulated blank notepad or locks immediately.
2. **Emergency Purge / Lockout:**
   In regions experiencing civil instability or targeted religious persecution, publishers can trigger an **Emergency Key Purge** (by entering a pre-configured duress PIN). This immediately destroys the local SQLCipher decryption key in the hardware Keystore, rendering all local databases unrecoverable without the remote master recovery passphrase.
