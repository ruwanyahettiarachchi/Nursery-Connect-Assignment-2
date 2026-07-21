# Nursery Connect (Assignment 2)

Nursery Connect is a native **iOS + watchOS** app suite, built with **SwiftUI** and **SwiftData**, for nursery/childcare staff to manage daily record-keeping — attendance, diary logs, safeguarding incidents, mood check-ins, and authorised collectors — in line with **EYFS** (Early Years Foundation Stage) record-keeping expectations. This is an expanded second iteration of the original Nursery Connect app, adding attendance registers, digital signatures, analytics, and a companion Apple Watch app.

## ✨ Features

- **Child list & profiles** — browse all children, with an adaptive layout (list on iPhone, sidebar + detail split view on iPad)
- **Daily diary logs** — record activity type, mood, naps (with sleep position and auto-calculated duration), nappy/toilet events, and meals
- **Safeguarding incident reports** — category, location, description, body-part/body-map location, immediate action taken, and witnesses
- **Digital sign-off workflow** — manager countersignature and parent acknowledgement captured via an on-screen **signature canvas**, satisfying duty-of-care documentation requirements
- **PDF export** — generate a shareable PDF report for any incident (via PDFKit)
- **Attendance register** — daily sign-in/sign-out tracking, capturing who dropped off/collected each child, their relationship, and whether the collector was on the **authorised collectors list**
- **Mood check-ins** — record wellbeing snapshots at arrival, midday, and departure
- **Analytics dashboard** — mood distribution, nap trends, incident body-part frequency, and weekly attendance charts
- **Apple Watch companion app** — at-a-glance today summary (children present, diary entries, incidents) synced from the iPhone app via `WatchConnectivity`, with attendance alerts
- **Fully offline, on-device storage** using SwiftData — no cloud sync, keeping sensitive child data local and private
- Automatic recovery from corrupted/incompatible local stores, with versioned schema migration handling

## 🛠 Tech Stack

- **Swift 5** / **SwiftUI** for both the iOS app and the watchOS companion
- **SwiftData** for local, on-device persistence (versioned schema, automatic store recovery)
- **PDFKit** + **UIKit** for generating incident report PDFs
- **WatchConnectivity** for iPhone ↔ Apple Watch data sync
- **XCTest** for unit tests, **XCUITest** for UI flow tests
- Xcode multi-target project: main app, unit tests, UI tests, and watchOS app

## 📂 Project Structure

```
Nursery-Connect-Assignment-2/
├── Nursery-Connect/                     # Main iOS app target
│   ├── App/
│   │   ├── Nursery_ConnectApp.swift     # App entry point, SwiftData ModelContainer + schema versioning
│   │   └── ContentView.swift            # Root view (device-adaptive)
│   ├── Models/
│   │   ├── Child.swift                  # Child entity
│   │   ├── DiaryLog.swift               # Diary entry (activity, nap, nappy, meals)
│   │   ├── Incident.swift               # Incident report (safeguarding workflow)
│   │   ├── AttendanceRecord.swift       # Daily sign-in/out record
│   │   ├── AuthorisedCollector.swift    # Parent-managed authorised collector list
│   │   └── MoodCheckIn.swift            # Arrival/midday/departure mood snapshots
│   ├── Services/
│   │   ├── IncidentPDFExporter.swift    # Renders an Incident as a PDF
│   │   ├── NurseryStaff.swift           # Keyworker directory (for witness selection)
│   │   ├── AttendanceSeedCleanup.swift  # One-time cleanup of old seeded demo data
│   │   ├── WatchSessionManager.swift    # WatchConnectivity session handling (iOS side)
│   │   └── WatchSummarySync.swift / WatchTodaySummary.swift  # Builds & syncs the watch summary payload
│   ├── ViewModels/
│   │   ├── AnalyticsViewModel.swift     # Mood/nap/incident/attendance aggregation for charts
│   │   └── AttendanceRegisterViewModel.swift  # Per-child attendance status logic
│   ├── Theme/
│   │   ├── NurseryTheme.swift           # App color palette / styling
│   │   └── Haptics.swift                # Haptic feedback helpers
│   └── Views/
│       ├── DashboardView.swift / ChildListView.swift / ChildDetailView.swift
│       ├── AddDiaryView.swift
│       ├── AddIncidentView.swift / IncidentDetailView.swift
│       ├── AttendanceRegisterView.swift / AttendanceCheckInSheet.swift / AttendanceCheckOutSheet.swift
│       ├── AuthorisedCollectorsView.swift
│       ├── MoodCheckInsView.swift
│       ├── AnalyticsView.swift
│       ├── SignatureCanvasView.swift / SignatureCaptureSheet.swift / ManagerSigningSheet.swift / ParentSigningSheet.swift
│       └── iPadRootView.swift           # Split-view navigation for iPad
├── Nursery-ConnectTests/                 # Unit tests (models, persistence)
├── Nursery-ConnectUITests/               # UI flow tests
└── NurseryConnectWatch/                  # watchOS companion app target
    ├── NurseryConnectWatchApp.swift
    ├── ContentView.swift                 # Today summary + quick attendance actions
    ├── Models/                           # Watch-side summary models
    └── Theme/WatchTheme.swift
```

## 🗄 Data Model

| Model | Key Fields | Purpose |
|---|---|---|
| `Child` | `name`, `age` | Core child record |
| `DiaryLog` | `activityType`, `mood`, nap start/end + `sleepPosition`, nappy/toilet fields, `meals` (JSON) | Daily care & activity record |
| `Incident` | `category`, `location`, `descriptionText`, body-map fields, `immediateActionTaken`, `witnesses`, manager/parent signature data | Safeguarding incident with sign-off workflow |
| `AttendanceRecord` | `signInTime`/`signOutTime`, drop-off/collector name & relationship, `collectorWasAuthorised` | Daily attendance & collection record |
| `AuthorisedCollector` | `name`, `relationship`, `photoIDReference` | Parent-managed list of people allowed to collect a child |
| `MoodCheckIn` | `timeOfDay`, `mood`, `notes` | Wellbeing snapshot at arrival/midday/departure |

All models persist locally via SwiftData under a versioned on-device store (currently schema version 6), with automatic fallback recovery if the store becomes incompatible or corrupted.

> ⚠️ **Privacy note:** This app processes information about children, which is treated as **special-category personal data** under UK GDPR (Article 9). Data is deliberately kept on-device (no cloud sync) to prioritise privacy and local control of records. If you extend this app with cloud sync or multi-device support, make sure to handle this data lawfully and securely.

## 🚀 Getting Started

### Prerequisites

- macOS with a recent version of **Xcode** supporting SwiftData and watchOS companion targets
- An iOS Simulator (and, optionally, a paired watchOS Simulator) or physical devices

### Running the app

1. Clone the repository
   ```bash
   git clone https://github.com/ruwanyahettiarachchi/Nursery-Connect-Assignment-2.git
   ```
2. Open `Nursery-Connect.xcodeproj` in Xcode.
3. Select the **Nursery-Connect** scheme with an iOS Simulator destination, then build and run (`⌘R`).
4. To try the watch companion, select the **NurseryConnectWatch** scheme with a paired watchOS Simulator, or run the app on a physical iPhone paired with an Apple Watch.

## 🧪 Testing

Run tests from Xcode (`⌘U`), or from the command line:

```bash
xcodebuild test \
  -project Nursery-Connect.xcodeproj \
  -scheme Nursery-Connect \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

This covers both model/persistence unit tests and end-to-end UI flow tests.

## 🧹 Housekeeping Note

This repository currently has a `build/` directory (Xcode's `DerivedData`/build output) committed at the root, which makes the repo unnecessarily large (several hundred MB). It's worth removing this from git history and adding it to `.gitignore`:

```
# .gitignore
build/
DerivedData/
*.xcuserstate
xcuserdata/
```

## 🧠 Key Concepts to Learn From This Project

This is a substantial step up from a typical CRUD app, and a great one to study for:

- **Cross-device app architecture** — sharing a data model between an iOS app and a watchOS companion via `WatchConnectivity` and App Groups
- **SwiftData schema versioning** and building resilient stores that can recover from incompatible/corrupted local databases
- Modeling a **multi-step sign-off workflow** (manager countersignature → parent acknowledgement) with captured signature data
- Generating **PDF documents programmatically** from structured data using PDFKit
- Building **adaptive SwiftUI layouts** that behave differently on iPhone vs iPad (`NavigationSplitView` for iPad, `iPadRootView`)
- Structuring a SwiftUI app with a clear **Models / ViewModels / Views / Services** separation
- Modeling **compliance-driven domain logic** (EYFS record-keeping, UK GDPR Article 9 special-category data) directly into your data model and code comments
- Writing SwiftData-backed **unit tests** using in-memory model containers

## 📄 License

This project is available for personal and educational use. Feel free to fork and adapt it for your own learning purposes.
