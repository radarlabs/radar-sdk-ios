## Code organization

Example/Example/
├── AppDelegate.swift            # Lifecycle, SDK init, store wiring, source registration
├── MainView.swift               # TabView shell
├── MyIAMDelegate.swift          # In-app message delegate
├── TripLiveActivityManager.swift
├── Utils.swift
│
├── Map/                         # Map tab — view layer
│   ├── MapView.swift            # Entry view + floating-button composition
│   ├── MapViewRepresentable.swift  # UIViewRepresentable + Coordinator + hit testing + region persistence
│   ├── OverlayPickerSheet.swift # Layer-toggle modal
│   ├── BuilderTrayView.swift    # Selected-destinations list + Start Trip CTA
│   ├── PendingHitOverlayView.swift # Tap-to-confirm card
│   └── ActiveTripBarView.swift  # Active-trip header + advance/reorder + complete/cancel
│
├── Tests/                       # Tests tab
│   ├── TestsView.swift          # Tab body — gear + recent activity + 6 panels
│   └── RecentActivitySection.swift # Last-5 LogStream preview
│
├── TestsSettings/               # Settings sheet behind the Tests-tab gear
│   ├── TestsSettingsView.swift  # Composer
│   ├── PresetSectionView.swift  # Preset grid + tracking/SDK-config disclosures
│   ├── IdentitySectionView.swift # userId / description / metadata
│   ├── TrackingSectionView.swift # On/off, source, configured options
│   └── PermissionsSectionView.swift # Location / notifications / motion / pending count
│
├── Logs/                        # Logs (Debug) tab
│   ├── LogsView.swift           # Header (Copy/Share/Clear) + filter chips + timeline
│   └── ConsoleEntryRow.swift    # Tappable row with expandable detail
│
├── Components/                  # Reusable UI primitives + SwiftUI bridge extensions
│   ├── ActionButton.swift       # Auto-logs taps; 3 styles (primary/secondary/destructive)
│   ├── ActivityShareSheet.swift # UIActivityViewController bridge for share sheet
│   ├── ConsoleEntry+UI.swift    # SwiftUI extensions on ConsoleEntry.Kind
│   ├── ConsoleEntry+Export.swift # Plain-text formatter for clipboard/share
│   ├── ControlRow.swift         # Settings-cell-style labeled row
│   ├── FieldEditor.swift        # Editable text field with clear button
│   ├── PermissionStatus+Display.swift # SwiftUI helpers on CL/UN authorization statuses
│   └── TogglePanel.swift        # Collapsible section
│
├── Panels/                      # Tests-tab content (consumed by Tests/TestsView)
│   ├── TrackingPanel.swift
│   ├── TripsPanel.swift
│   ├── VerifiedPanel.swift
│   ├── SearchPanel.swift
│   ├── NotificationsPanel.swift
│   └── MessagingPanel.swift
│
├── Services/                    # Stateful, observable bridges + cross-cutting value types
│   ├── LogStream.swift          # RadarDelegate + console source-of-truth
│   ├── SettingsStore.swift      # SDK-backed identity + tracking + field breakdowns
│   ├── PermissionsStore.swift   # CLAuthorizationStatus + UNAuthorizationStatus
│   ├── TripBuilderStore.swift   # Map-driven trip selection + active-trip mirror
│   ├── TestPreset.swift         # Bundled tracking presets
│   ├── TripDestination.swift    # Builder-tray destination enum
│   └── TripEventMarker.swift    # Trip event captured for map-pin rendering
│
└── MapOverlays/                 # Map source plugins
    ├── MapOverlaySource.swift   # Protocol + bundle struct + trip-mode whitelist
    ├── MapOverlayRegistry.swift # Source registry, enabled-state, refresh, trip-mode
    ├── GeofenceOverlay.swift    # Common protocol for tappable geofence overlays
    ├── MonitoredRegionsSource.swift
    ├── NearbyGeofencesSource.swift
    ├── NearbyPlacesSource.swift
    ├── SyncedRegionSource.swift
    ├── TripGeofenceSource.swift
    ├── TripDestinationSource.swift
    ├── TripBreadcrumbsSource.swift
    └── TripEventsSource.swift

## Conventions

- New code is Swift only (matches root `AGENTS.md`).
- One `ObservableObject` per concern. Don't merge stores; cross-store coordination lives in `AppDelegate` or in store-to-store `bind(...)` methods.
- All console output flows through `LogStream`. Don't `print()`; use `logStream.write(...)`.
- All SDK delegate callbacks must go through `LogStream`. Don't call `Radar.setDelegate(_:)` from anywhere else.
- Trip lifecycle state lives in `TripBuilderStore`. New trip-related features should hang off that store rather than introducing parallel mirrors of `Radar.getTrip()`.

### File organization

- **Tab/feature views live in a folder named after the tab** (`Map/`, `Tests/`, `TestsSettings/`, `Logs/`). The parent view keeps the unadorned name (e.g. `LogsView.swift`); sub-views use descriptive names (e.g. `ConsoleEntryRow.swift`, `ActiveTripBarView.swift`).
- **One subview per file.** Every `some View` returning property/method that produces a discrete UI section should be its own `View` struct in its own file, taking inputs as `@ObservedObject`/`@EnvironmentObject`/parameters. Trivial inline view-builders (< ~15 lines, single-use, no state) may stay inline.
- **Helpers stay home.** Pure helpers — formatters, predicates, color/string mappers, `static let` constants — stay alongside the parent view. They're not components.
- **`Components/` is for reusable primitives** (e.g. `ActionButton`, `ControlRow`, `FieldEditor`) and **SwiftUI bridge extensions on non-UI types** (e.g. `ConsoleEntry+UI`, `PermissionStatus+Display`). Feature-specific subviews never go here.
- **`Panels/` holds Tests-tab content**; map plugins live in `MapOverlays/`; service classes live in `Services/`.
- **Cross-cutting model types** (enums, value types, marker structs) referenced by multiple files belong in `Services/` alongside the store that owns their lifecycle, not nested inside the store's `.swift` file (see `TripDestination.swift`, `TripEventMarker.swift`).
- **MARKs in larger files.** Any file over ~150 lines uses `// MARK: - Section name` separators grouped by responsibility (state, view bodies, helpers, nested types).
- **One top-level type per file.** `UIViewRepresentable` wrappers, `Coordinator`s, and modal sheets each get their own file under the parent view's folder.
