# Ozioma — Google Play Console Store Listing, Data Safety & Privacy Policy Handbook

**Application Identifier:** `com.kovaro.ozioma`  
**Firebase Project:** `hexadigitall-ozioma-fs-prod` (`ozioma-fs`)  
**Target Category:** Productivity / Lifestyle  
**Classification:** Canonical Store Submission Document  

---

## 1. Google Play Console Listing Metadata

### 1.1 App Title & Descriptions

- **App Name:** `Ozioma: Field Ministry & Territories` *(38 / 50 characters)*
- **Short Description:** *(79 / 80 characters)*  
  `Worldwide theocratic territory management, sunlight door logging & service timer.`
- **Full Description:**
```markdown
Ozioma is a theocratic, local-first platform engineered specifically for Christian publishers and congregation servants engaged in the global field ministry. Designed from the ground up for one-handed operation in bright sunlight, Ozioma ensures your territory records, return visits, and service reports remain organized, battery-efficient, and privacy-protected.

KEY FEATURES:

• SUNLIGHT ULTRA-CONTRAST MODE (WCAG AAA)
Engineered for bright equatorial daylight with high-visibility contrast ratios (7:1), large touch targets (≥48x48dp), and anti-glare color palettes.

• ZERO-CLOUD PII & HARDWARE-ENCRYPTED RV CRM
Householder names, phone numbers, and visit notes are strictly classified as Restricted Local PII. They are encrypted directly on your device with AES-256-GCM via the Android Hardware Keystore. Your personal return visit notes are never transmitted to cloud servers.

• OFFLINE VECTOR MAPS (WORLDWIDE)
Spool compact vector map tiles across preaching territories worldwide (Americas, Europe, Africa, Asia-Pacific) using PMTiles/MBTiles via Cloudflare R2 CDN. Navigate street boundaries, start points, and stop pins completely offline without cellular data.

• 1-HANDED RAPID DOOR LOGGER
Log door statuses (Unvisited, Not at Home, Return Visit, Do Not Call) with single-handed thumb reaches, tactile haptic feedback, and a 5-second instant undo buffer.

• FIELD SERVICE TIMER & S-4 REPORT GENERATOR
Track daily ministry sessions with an integrated foreground timer, pause/resume, and credit hour adjustments. Automatically aggregate monthly hours and share your official S-4 Field Service Report directly with your Group Overseer via WhatsApp or SMS.

• "ENJOY LIFE FOREVER!" BIBLE STUDY TRACKER
Track progressive Bible student development across Lessons 1–60 with interactive progress indicators, lesson notes, and call-schedule reminders.

• SERVICE GROUP REALTIME PRESENCE (OPTIONAL)
Share location with ministry partners during morning service hours (8:00 AM – 12:00 PM) with a randomized ±15m privacy offset to prevent pinpointing exact residential doors. Automatically terminates at 12:00 PM.

• DUAL-PLATFORM NATIVE POWER TOOL
Seamlessly synchronize congregation territory boundaries with the dedicated Ozioma Desktop administrative suite (Tauri 2.0 Rust) for Territory Overseers, S-13 vector PDF printing, and Circuit Overseer S-8 analytics.
```

### 1.2 Target Audience & Content Rating
- **Target Audience:** Ages 13 and older (Publishers, Pioneers, Elders, Congregation Servants).
- **Content Rating:** Everyone (IARC Certificate: No violence, no adult themes, no user-generated open forums).

---

## 2. Google Play Console Data Safety Questionnaire

Complete the **Data Safety** section in Google Play Console with these exact verified answers:

### Section A: Data Collection & Sharing Overview
- **Does your app collect or share any of the required user data types?**  
  ➔ **Yes** *(Location for navigation/presence; Account info for congregation authentication).*
- **Is all of the user data collected by your app encrypted in transit?**  
  ➔ **Yes** *(All network communications use TLS 1.3 / HTTPS / WSS).*
- **Do you provide a way for users to request that their data be deleted?**  
  ➔ **Yes** *(Users can delete their account in settings or trigger an emergency duress key purge that immediately destroys local encryption keys).*

### Section B: Data Types Breakdown

| Data Category | Specific Type | Collected? | Shared? | Purpose | Ephemeral? |
| :--- | :--- | :---: | :---: | :--- | :---: |
| **Location** | Approximate Location | **Yes** | **No** | Territory boundary navigation & partner presence ($\pm 15$m jitter) | **Yes** |
| **Location** | Precise Location | **Yes** | **No** | Proximity voice alerts to territory START/STOP boundary pins | **Yes** |
| **Personal Info** | Name & Email Address | **Yes** | **No** | Account management & congregation territory assignment verification | No |
| **Personal Info** | Householder PII (Names, Notes) | **NO** | **NO** | **Stored purely on-device**, encrypted with AES-256-GCM via Keystore | N/A |
| **App Activity** | Page Views / Button Taps | **No** | **No** | Analytics tracking is disabled by default | N/A |
| **Financial Info**| Payment / Credit Cards | **No** | **No** | Not collected (Ozioma is completely free) | N/A |

### Section C: Security & Privacy Declarations
1. **Encryption in Transit:** All data transmitted between the client and Supabase/PowerSync is encrypted using industry-standard TLS 1.3.
2. **On-Device Cryptography:** Sensitive theocratic householder notes remain strictly on-device, protected by Android Keystore hardware-backed AES-256 encryption.
3. **Third-Party Trackers:** Zero advertising SDKs, zero third-party marketing trackers, zero telemetry monetization.

---

## 3. Official Theocratic Privacy Policy

*(Host this policy at `https://hexadigitall.github.io/ozioma/privacy-policy` or your domain)*

```markdown
# Privacy Policy for Ozioma

**Last Updated:** November 24, 2026  
**Developer:** Hexadigitall / Kovaro Platform  
**Package:** `com.kovaro.ozioma`  

### 1. Commitment to Theocratic & Personal Privacy
Ozioma ("we", "our", or "the app") is committed to upholding the highest international standards of data privacy (including GDPR, CCPA, LGPD, NDPA, APPI, and POPIA) while serving Christian congregations worldwide.

### 2. Zero-Cloud PII Architecture (Householder Records)
We strictly adhere to a **Zero-Cloud PII (Personally Identifiable Information)** architecture:
- Names, physical addresses, phone numbers, family details, and personal visit notes concerning householders are classified as **Restricted Local PII**.
- This data is stored **exclusively in encrypted SQLite on your physical device**, encrypted with AES-256-GCM using hardware-backed cryptographic keys managed by the Android Keystore / iOS Keychain.
- Restricted Local PII is **never transmitted, synchronized, backed up, or logged to cloud servers**.

### 3. Data We Process in the Cloud
Cloud synchronization via PowerSync and Supabase is strictly limited to:
1. **User Authentication:** Email address and display name for signing into your congregation account.
2. **Congregation Boundaries:** Anonymized territory boundary polygons (GeoJSON) and public street names.
3. **Aggregated Status:** Anonymized door statuses (e.g., Unvisited, Not at Home, Completed) without personal householder identities.
4. **Ministry Totals:** Monthly ministry hours, literature placements, and video totals for S-4 report generation.

### 4. Location Data Usage
- **Navigation:** Used in real time to calculate proximity to assigned territory boundary pins. Location data is processed on-device.
- **Service Partner Presence (Optional):** When explicitly toggled on during morning ministry hours (8:00 AM – 12:00 PM), approximate location is broadcast with a randomized ±15-meter privacy offset to prevent identifying specific households. Broadcasting automatically terminates at 12:00 PM or after 4 hours.

### 5. Data Retention & Emergency Purge
Users retain full control of their records:
- **Local Data Deletion:** Clearing app storage or triggering an emergency key purge immediately and irreversibly destroys decryption keys.
- **Account Deletion:** Users can request immediate deletion of their cloud profile and synchronized ministry logs by contacting their Congregation Administrator.

### 6. Contact
For questions regarding this privacy policy or data protection compliance:  
**Email:** privacy@hexadigitall.com / support@ozioma.org  
**Organization:** Hexadigitall Engineering Team  
```
