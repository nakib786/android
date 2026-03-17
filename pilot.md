You are an expert mobile app developer specializing in Flutter (Dart).
Build a complete, production-ready, premium Mileage Tracker app that
runs on both Android and iOS from a single codebase.

NO LOGIN / NO AUTH / NO FIREBASE — everything is stored locally on device.
This app is designed specifically for CANADIAN users and must be fully
compliant with CRA (Canada Revenue Agency) 2026 mileage deduction rules.
Rates announced January 14, 2026 — effective January 1, 2026.

=======================================================
APP NAME: Aurora — CRA Mileage Tracker
TAGLINE: "Every kilometre counts at tax time."
FRAMEWORK: Flutter (Dart) — single codebase for Android + iOS
STATE MANAGEMENT: Riverpod
LOCAL DATABASE: Isar (fast, offline, no setup needed)
MAPS: Google Maps Flutter SDK + Geolocator
CHARTS: fl_chart
EXPORT: pdf + csv + share_plus packages
NOTIFICATIONS: flutter_local_notifications
DEFAULT UNIT: Kilometres (not miles)
DEFAULT CURRENCY: CAD ($)
TAX AUTHORITY: CRA (Canada Revenue Agency)
TAX YEAR: 2026 (January 1 – December 31, 2026)
NO backend, NO Firebase, NO internet required
=======================================================

=======================================================
SECTION 1 — OFFICIAL 2026 CRA TAX RULES & RATES
=======================================================
Implement the following OFFICIAL 2026 CRA rates as
configurable constants in core/constants/cra_rates.dart
(user can update manually each year in Settings):

BUSINESS / EMPLOYMENT USE (Provincial — all provinces):
- First 5,000 km of the tax year: $0.73 per km
- Each km after 5,000 km:        $0.64 per km

NORTHERN TERRITORIES (NT, YT, NU — higher allowance):
- First 5,000 km of the tax year: $0.77 per km
- Each km after 5,000 km:         $0.71 per km

NOTE: Northern territories rates are exactly $0.04/km
higher than provincial rates across both tiers.
Auto-apply northern rates when user selects NT, YT, 
or NU as their province in settings/onboarding.

MEDICAL / MOVING USE:
- Flat rate: $0.21 per km (user editable)

CHARITY / VOLUNTEER USE:
- Flat rate: $0.14 per km (user editable)

PERSONAL USE:
- No deduction (tracked for business use % only)

YEAR-OVER-YEAR RATE HISTORY (display in settings 
as a reference card, read-only):
- 2026: $0.73 / $0.67 (provinces) | $0.77 / $0.71 (territories)
- 2025: $0.72 / $0.66 (provinces) | $0.76 / $0.70 (territories)
- 2024: $0.70 / $0.64 (provinces) | $0.74 / $0.68 (territories)
- 2023: $0.68 / $0.62 (provinces) | $0.72 / $0.66 (territories)

TAX DEDUCTION CALCULATION LOGIC:
- Track cumulative business km across the calendar year
  (January 1 to December 31)
- Automatically apply $0.73/km until cumulative 
  business km reaches 5,000 for the year
- Automatically switch to $0.67/km for all business 
  km beyond 5,000 for the year
- If a single trip crosses the 5,000 km threshold:
  split the trip — apply $0.73 to km before threshold,
  $0.67 to km after threshold, sum both for the trip
- Northern users: same logic using $0.77 / $0.71
- Show a live progress bar: 
  "X of 5,000 km used at $0.73/km rate"
- Once threshold crossed, update banner to:
  "All business km now earning $0.64/km"

BUSINESS USE % (CRA logbook requirement):
- Calculate: business km ÷ total km × 100
- Show this % prominently on dashboard
- CRA uses this % to determine what portion of actual
  vehicle expenses can be deducted by self-employed
- Display warning if business use % < 10% 
  (CRA may flag very low business use)

CRA LOGBOOK COMPLIANCE (mandatory fields per trip):
- Date of trip ✅
- Departure point (start address) ✅
- Destination ✅
- Purpose of the trip (required for business) ✅
- Number of kilometres driven ✅
- Vehicle used ✅
All 6 fields required for a trip to be marked 
"CRA Compliant" — show compliance badge on each trip

WHAT QUALIFIES AS BUSINESS DRIVING (show in app):
✅ Travel to client meetings
✅ Travel between job sites
✅ Picking up business supplies
✅ Going to a temporary work location
✅ Travel to CRA or accountant for business matters
❌ Commuting from home to regular workplace
❌ Personal errands
❌ Vacation travel

=======================================================
SECTION 2 — PROJECT STRUCTURE
=======================================================
Use a clean feature-first folder structure:

lib/
├── core/
│   ├── constants/
│   │   ├── cra_rates.dart       ← 2026 official rates
│   │   ├── cra_categories.dart  ← Business/Medical etc
│   │   ├── provinces.dart       ← All 13 provinces/territories
│   │   └── app_constants.dart   ← colours, strings
│   ├── theme/
│   │   ├── app_theme.dart       ← light + dark themes
│   │   └── app_colours.dart     ← Canadian red palette
│   ├── utils/
│   │   ├── km_formatter.dart
│   │   ├── cad_formatter.dart
│   │   ├── date_formatter.dart  ← Canadian date formats
│   │   └── cra_calculator.dart  ← deduction engine
│   └── services/
│       ├── gps_service.dart
│       └── notification_service.dart
├── features/
│   ├── dashboard/
│   ├── trips/
│   ├── tracking/
│   ├── vehicles/
│   ├── reports/
│   └── settings/
├── shared/
│   ├── widgets/
│   └── models/
│       ├── trip.dart
│       ├── vehicle.dart
│       └── odometer_log.dart
└── main.dart

=======================================================
SECTION 3 — ONBOARDING (First Launch Only)
=======================================================
- 3-slide onboarding on first launch only
- Slide 1: "Track Every Kilometre"
    GPS auto tracking intro, Aurora logo animation
- Slide 2: "Maximize Your 2026 CRA Deductions"
    Show the actual 2026 rate: $0.73/km (first 5,000 km)
    Explain the tier split rule in plain English
- Slide 3: "Your Data Stays on Your Phone"
    No account, no cloud, no tracking — 100% private
- Province/Territory selector on last slide:
    Dropdown of all 13 provinces + territories
    Shows northern rates automatically if NT/YT/NU 
    selected ("You qualify for $0.77/km!")
- Skip + Get Started buttons
- Save: onboarding_complete + selected_province 
  to SharedPreferences
- Never show again after completion

=======================================================
SECTION 4 — DASHBOARD (Home Screen)
=======================================================
Beautiful home dashboard showing:

TOP BANNER (tappable → Settings):
"🍁 2026 CRA Rate: $0.73/km (first 5,000 km) 
 · $0.67/km after"
For northern users: "$0.77/km · $0.71/km after"

SUMMARY CARDS (2×2 grid):
- Total km this month
- Business km this year  
- Estimated CRA deduction this year (CAD)
- Business use % (business ÷ total × 100)

5,000 KM THRESHOLD PROGRESS BAR:
"2,840 of 5,000 km at $0.73/km"
Green progress bar filling toward 5,000
Once exceeded: banner changes to amber
"✅ 5,000 km threshold crossed — now $0.67/km"

CHARTS:
- Bar chart (fl_chart): km per week, last 6 weeks
- Pie chart (fl_chart): trips by CRA category

QUICK ACTIONS ROW:
- "🚗 Start Trip"
- "✏️ Log Manually"  
- "📊 CRA Report"

RECENT TRIPS (last 5):
- Each shows: date, route, km, category badge, 
  deduction in CAD, CRA compliance badge (✅/⚠️)
- Swipe left to delete

CRA COMPLIANCE ALERT (if issues exist):
Amber banner: "⚠️ 3 trips missing purpose — 
tap to fix before tax season"

=======================================================
SECTION 5 — LIVE GPS TRIP TRACKING
=======================================================

5A — TRACKING SCREEN:
- Full-screen Google Map on user's location
- Animated pulsing blue dot
- Real-time polyline as user drives
- Top overlay card:
    * Live km (updates every second)
    * Live timer (HH:MM:SS)
    * Current speed (km/h)
- Bottom sheet buttons:
    * "START TRIP" (large, green)
    * Becomes "PAUSE" + "STOP" once started
- Background tracking (works with screen off)
- Uses geolocator + background_locator_2

5B — TRIP SUMMARY POPUP (after stop):
- Map snapshot of route
- Total km driven
- Duration  
- Start address + End address (reverse geocoded)
- CRA TRIP PURPOSE (required field ⚠️):
    Text input: e.g. "Client meeting — Acme Corp,
    123 Main St, Vancouver"
    Red border + warning if left empty for Business
- CRA Category picker:
    🔵 Business | 🟢 Medical | 🟠 Moving
    🟡 Charity  | ⚫ Personal
- Vehicle selector
- Optional notes
- Estimated CRA deduction (auto-calculated in CAD)
- Shows which rate was applied:
    "Calculated at $0.73/km (below 5,000 km)"
    OR "Calculated at $0.67/km (above 5,000 km)"
    OR "Split: X km at $0.73 + Y km at $0.67"
- SAVE TRIP / DISCARD buttons

=======================================================
SECTION 6 — MANUAL TRIP ENTRY
=======================================================
Full CRA-compliant form:
- Date & time picker
- Start location (text + map pin picker)
- End location (text + map pin picker)
- Distance in km (auto-calculated OR manual input)
- Round trip toggle (doubles the km)
- Duration (optional)
- CRA Trip Purpose (required for business) 
- CRA Category dropdown
- Vehicle dropdown
- Notes
- Full validation — warn if business trip 
  has no purpose
- Edit existing trips via same form

=======================================================
SECTION 7 — TRIP HISTORY SCREEN
=======================================================
- Full searchable trip list
- Search: location, purpose, notes
- Filter chips: All / Business / Medical / 
  Moving / Charity / Personal
- Sort: Newest / Oldest / Longest / Shortest
- Each trip card:
    * Date (e.g. Mon, Jan 15, 2026)
    * Start → End location
    * Kilometres + duration
    * CRA purpose snippet
    * Category badge (colour-coded)
    * Deduction in CAD (green)
    * ✅ CRA Compliant OR ⚠️ Missing fields
- Tap → full detail with map route + 
  which CRA rate was applied
- Swipe left → Delete (undo snackbar)
- Swipe right → Duplicate
- Long press → Multi-select bulk delete
- CRA warning icon on non-compliant trips

=======================================================
SECTION 8 — VEHICLE MANAGEMENT
=======================================================
- Add / Edit / Delete vehicles
- Fields:
    * Nickname (e.g. "My RAV4", "Work Truck")
    * Make, Model, Year
    * License plate (Canadian format)
    * Province of registration (all 13 options)
    * Colour picker
    * Vehicle type icon: car/truck/van/SUV/motorcycle
- Set default vehicle
- Per-vehicle stats:
    * Total km this year
    * Business km this year
    * Estimated deduction this year
- Odometer log:
    * Manual odometer readings with date
    * CRA may request start + end of year readings
    * Auto-calculates annual total km from readings

=======================================================
SECTION 9 — CRA REPORTS & EXPORT
=======================================================

9A — FILTERS:
- Presets: This Week / This Month / This Quarter /
  This Tax Year (Jan 1 – Dec 31, 2026) / Custom Range
- Filter by: vehicle, CRA category
- Tax year = calendar year

9B — REPORT SUMMARY:
- Total km by CRA category
- Business km breakdown:
    * km at $0.73/km (first 5,000)
    * km at $0.67/km (after 5,000)
    * Total business deduction in CAD
- Medical/Moving deduction total
- Charity deduction total
- Business use % vs personal
- Number of trips
- Average trip distance
- Longest trip
- Bar chart: km by month
- Pie chart: by CRA category

CRA COMPLIANCE CHECKER (pre-export checklist):
✅ All business trips have a purpose entered
✅ All trips have a vehicle assigned
✅ All trips have start + end location
⚠️ Tap to fix any non-compliant trips before export

9C — EXPORT:

PDF EXPORT (CRA Motor Vehicle Logbook format):
Header:
  "CRA Motor Vehicle Expense Logbook — Tax Year 2026"
  User name (optional, user fills in)
  Province / Territory
  Reporting period (date range)

Vehicle section per vehicle used:
  Make | Model | Year | Plate | Province

Trip table columns:
  Date | Departure | Destination | Purpose | 
  Km | Category | Rate Applied | Deduction (CAD)

Summary section:
  Total km driven (all purposes)
  Business km — first 5,000 km @ $0.73/km = $X
  Business km — above 5,000 km @ $0.67/km = $X
  Total Business Deduction: $X CAD
  Medical/Moving Deduction: $X CAD
  Charity Deduction: $X CAD
  TOTAL CRA DEDUCTION: $X CAD
  Business Use %: X%
  Note: "Keep this log with your tax records. 
  CRA may request it for up to 6 years."

Footer: "Generated by Aurora | 2026 CRA Rates"

CSV EXPORT:
Same columns as PDF table
Opens cleanly in Excel / Google Sheets / CRA forms

SHARE via system sheet:
Email, iCloud Drive, Google Drive, 
WhatsApp, AirDrop, Dropbox

=======================================================
SECTION 10 — SETTINGS SCREEN
=======================================================
- Province / Territory selector (all 13):
    AB, BC, MB, NB, NL, NS, NT, NU, ON,
    PE, QC, SK, YT
    Auto-applies northern rates for NT, YT, NU

- 2026 CRA RATES (fully editable by user):
    Business tier 1 (first 5,000 km): $0.73/km
    Business tier 2 (after 5,000 km): $0.67/km
    Northern tier 1 (first 5,000 km): $0.77/km
    Northern tier 2 (after 5,000 km): $0.71/km
    Medical / Moving rate:             $0.21/km
    Charity rate:                      $0.14/km
    5,000 km threshold:                5,000 km
    "Reset to 2026 CRA defaults" button

- RATE HISTORY REFERENCE CARD (read-only):
    2026: $0.73 / $0.67 | Territories: $0.77 / $0.71
    2025: $0.72 / $0.66 | Territories: $0.76 / $0.70
    2024: $0.70 / $0.64 | Territories: $0.74 / $0.68
    2023: $0.68 / $0.62 | Territories: $0.72 / $0.66

- Tax year threshold reset:
    Auto-resets annual km counter on January 1

- Distance unit toggle: Kilometres / Miles
- Currency: CAD $ (default)
- Theme: Light / Dark / System
- Font size: Normal / Large

- NOTIFICATIONS:
    Daily reminder to log trips + time picker
    Weekly summary (Sundays)
    Tax season reminder (fires December 1):
      "📋 Tax season is coming — review your 
       Aurora logbook!"
    5,000 km milestone alert:
      "🎯 You've driven 5,000 business km! 
       Rate now drops to $0.67/km"
    Odometer reminder (monthly prompt to 
      record odometer reading)

- DATA MANAGEMENT:
    Export full JSON backup
    Import from backup file
    Clear all trips (with confirmation dialog)
    Clear all vehicles
    "What data is stored?" explainer (privacy)

- CRA INFORMATION HUB (in-app, no internet):
    Plain-language guide: 
      "What qualifies as a business trip?"
    Plain-language guide:
      "Self-employed vs employee — different rules"
    2026 CRA rates reference card
    CRA 6-year record-keeping rule reminder
    Link to: canada.ca automobile expenses page

- App info: version, privacy policy, open source licences

=======================================================
SECTION 11 — PREMIUM UI/UX
=======================================================
- Material Design 3 (Material You) throughout
- Full light + dark theme
- Primary brand colour: Canadian red #D52B1E
  with white #FFFFFF and charcoal #1C1C1E
- Google Font: "Plus Jakarta Sans"
- Animated bottom nav (5 tabs):
    🏠 Home | 🗒 Trips | 🚗 Track | 📊 Reports | ⚙️ Settings
- Smooth Hero + Fade screen transitions
- Skeleton shimmer loading on all list screens
- Illustrated empty states with CTA buttons
- Pull-to-refresh on all lists
- Haptic feedback on taps and swipes
- Tablet-responsive layout
- All amounts: CAD format (e.g. $142.80)
- All distances: km (e.g. 23.4 km)
- Canadian date format: January 15, 2026
  ISO format in exports: 2026-01-15
- CRA warnings in amber #FF9800
- CRA compliance badges: green ✅ / amber ⚠️
- Snackbar confirmation on all actions

=======================================================
SECTION 12 — PUBSPEC.YAML DEPENDENCIES
=======================================================
Generate complete pubspec.yaml including:
- isar + isar_flutter_libs + isar_generator
- riverpod + flutter_riverpod + hooks_riverpod
- google_maps_flutter
- geolocator + background_locator_2
- geocoding
- fl_chart
- pdf + printing
- csv + share_plus
- flutter_local_notifications
- shared_preferences
- google_fonts
- shimmer
- gap
- intl
- path_provider
- permission_handler
- flutter_svg

=======================================================
SECTION 13 — ADDITIONAL INSTRUCTIONS
=======================================================
- ALL files complete — no placeholders, no //TODO,
  no truncated code
- Every screen fully functional end-to-end
- All Isar models with proper annotations
- All Riverpod providers properly scoped
- Handle all permissions gracefully with 
  rationale dialogs in English AND French
  (Canada is officially bilingual)
- Handle GPS off → enable GPS dialog
- Handle no location permission → settings redirect
- App works 100% OFFLINE — zero internet calls
- AndroidManifest.xml must include:
    ACCESS_FINE_LOCATION
    ACCESS_BACKGROUND_LOCATION
    FOREGROUND_SERVICE
- Info.plist iOS location usage strings:
    English + French (bilingual)
- Auto-reset annual km counter on January 1
- Generate README.md with:
    Setup instructions
    How to add Google Maps API key
    How to run on Android and iOS
    How to update CRA rates each new year
    CRA 6-year record-keeping reminder for users

Output every file one by one in this order:
1. pubspec.yaml
2. main.dart
3. core/constants/cra_rates.dart (2026 official rates)
4. core/constants/provinces.dart
5. core/theme files
6. core/utils/cra_calculator.dart (deduction engine)
7. Isar models (trip, vehicle, odometer)
8. Services (GPS, notifications)
9. Features — screen by screen
10. AndroidManifest.xml + Info.plist
11. README.md