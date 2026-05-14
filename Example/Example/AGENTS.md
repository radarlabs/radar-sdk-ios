# Example app

The Radar iOS example app is the project's primary functional-testing surface. This file is the authoritative reference for what each control does, what to expect in the console, and how to extend the app.

Audience: human QA testers and AI coding agents working on the SDK or the example app itself. Read this together with the root `AGENTS.md`.

## Purpose

Three jobs, in priority order:

1. Reproducible functional tests of the SDK from a tester's seat.
2. A scratchpad for verifying SDK changes during development.
3. A living example of how a host app integrates the SDK.

When in doubt, prefer the testability story over example-cleanliness. (Side panels, debug labels, breakdowns, etc. are fine.)

## App at a glance

- Bundle: `Example.xcodeproj`, scheme `Example`.
- Deployment target: iOS 14.0 (the SDK supports 12+; the example only constrains its own UI).
- Default selected tab: **Tests**.
- Default publishable key: hardcoded `prj_test_pk_…` in `SettingsStore.defaultPublishableKey`. Override path exists in `SettingsStore.publishableKeyOverride` (UserDefaults) but no UI surfaces it yet.
- App group: `group.waypoint.data` (see `AppDelegate.didFinishLaunchingWithOptions`).
- Notifications, deep-link auto-handling, and silent push are enabled at launch.

## Tab inventory

| Tab bar label | Enum case | View | Purpose |
|---|---|---|---|
| Map | `.Map` | `MapView` | Visualize SDK state and run interactive trip flows |
| Debug | `.Logs` | `LogsView` | Read the unified console timeline |
| Tests | `.Tests` | `TestsView` | Isolated API actions; access settings via gear |

(The tab label "Debug" maps to the `.Logs` case — historical naming. The view file is `LogsView.swift`.)

## The five stores

All five are `@EnvironmentObject`s wired in `AppDelegate.scene(_:willConnectTo:)`. Read this section before adding new state.

### `LogStream`

Single source of truth for SDK delegate callbacks AND user-action logging.

- Registered as `Radar.setDelegate(_:)` — only one delegate is allowed by the SDK, so nothing else may register.
- Owns the unified `entries: [ConsoleEntry]` timeline (cap 2000, FIFO).
- Has dedicated `PassthroughSubject` publishers for non-UI consumers (e.g. `TripLiveActivityManager`, `TripBuilderStore`).
- UI consumers read `@Published` state. Don't subscribe to publishers from views.

### `SettingsStore`

Bridge between SwiftUI bindings and the SDK / UserDefaults.

- **SDK-backed (read/write):** `userId`, `userDescription`, `metadata` — `didSet` writes through to `Radar.setUserId/.setDescription/.setMetadata` and clears `activePresetId` (so manual edits drop the preset highlight).
- **SDK-backed (read-only snapshots):** `isTracking`, `isUsingRemoteOptions`, `trackingOptionsSummary` — refreshed only by `refresh()`. Call after any operation that may have changed tracking state.
- **App-only (UserDefaults):** `publishableKeyOverride`, `defaultTabRaw`.
- **Field breakdowns for UI:** `currentTrackingFields` and `currentSdkConfigFields` produce `[TrackingField]` for the disclosure groups in `TestsSettingsView`.
- **Preset application:** `apply(_: TestPreset)` writes identity, performs the tracking action, and refreshes — see Presets section.

### `PermissionsStore`

Observable mirror of system permission state.

- Tracks `locationStatus: CLAuthorizationStatus` and `notificationStatus: UNAuthorizationStatus`.
- Re-polls notification status on app foreground.
- `requestLocation()` escalates progressively: notDetermined → when-in-use → always.
- `requestMotionActivity()` triggers the prompt via `Radar.requestMotionActivityPermission()`. iOS does not expose motion authorization status, so the UI shows a Request button and no current status.
- `openSystemSettings()` deep-links to the app's Settings page (use for denied/restricted).

### `MapOverlayRegistry`

`@MainActor` registry of `MapOverlaySource` instances and their enabled-state.

- Sources are registered in `AppDelegate.didFinishLaunchingWithOptions`.
- `enabledSourceIds: Set<String>` is persisted to UserDefaults.
- `isInTripMode: Bool` — flips to `true` whenever `TripBuilderStore.activeTrip` is non-nil. While true, only sources with `isTripModeWhitelisted == true` render. User toggle state is preserved (just temporarily ignored) and restored when the trip ends.
- `refresh(near:span:)` runs each currently-enabled source's `loadOverlays(...)` sequentially and stores bundles in `bundlesById`.
- `refreshSource(_:)` reloads one source's bundle — used for data-driven sources (breadcrumbs, events) that change between map pans. Requires `lastKnownLocation` to be set; pre-map-load calls are no-ops.
- `clearBundle(for:)` drops a cached bundle, used when a source's underlying state is reset (e.g., trip ends).
- The map view binds to `allOverlays` and `allAnnotations`; rendering dispatches via `renderer(for:)` and `view(for:in:)` to whichever source produced the item.

### `TripBuilderStore`

`@MainActor` store that owns the map-driven trip flow: pre-trip destination selection, the active trip mirror, and lifecycle actions.

- **Selection state:** `selectedDestinations: [TripDestination]`, `pendingHit: TripDestination?`. Methods: `add`, `remove(at:)`, `remove(at offsets:)`, `move(from:to:)`, `clear`, `proposeHit`, `confirmPendingHit`, `dismissPendingHit`, `isSelected`.
- **Active-trip mirror:** `@Published activeTrip: RadarTrip?` reflects `Radar.getTrip()`. Refreshed automatically on every event-publisher tick and after each in-store SDK action.
- **Visualization state:** `tripBreadcrumbs: [CLLocationCoordinate2D]` and `tripEventMarkers: [TripEventMarker]`. Both reset when `activeTrip` transitions from non-nil to nil.
- **Wiring:** `bind(logStream:registry:)` (called from AppDelegate) subscribes to `didReceiveEventsPublisher` (for active-trip refresh + event capture) and `didUpdateLocationPublisher` (for breadcrumbs). Holds weak references to both.
- **Lifecycle actions:** `startTrip()`, `advanceCurrentLeg(_:)`, `completeTrip()`, `cancelTrip()`, `moveLeg(legId:direction:)`. All log to `LogStream` and refresh active-trip state on completion.

`startTrip()` branches on selection shape:
- Single-destination geofence (tag + externalId both present) → traditional `RadarTripOptions(destinationGeofenceTag:destinationGeofenceExternalId:)`.
- Anything else (multiple destinations, coordinate-only, geofence without both ids) → `options.legs = [...]` multi-leg shape.

## Tests tab — action catalog

Every button in `TestsView` is one `ActionButton`. Each tap auto-logs to the console as an `.action` entry. Most actions also log a `.result` (or `.error`) entry when the SDK call returns.

### Tracking panel (expanded by default)

| Button | SDK call | Console expectation |
|---|---|---|
| `trackOnce` | `Radar.trackOnce()` | `LOG` entries from the SDK; if successful, a `LOCATION` entry from `didUpdateLocation` |
| `startTracking (responsive)` | `Radar.startTracking(trackingOptions: .presetResponsive)` | `LOG` entries; subsequent `LOCATION` entries on cadence |
| `startTracking (continuous)` | `Radar.startTracking(trackingOptions: .presetContinuous)` | Same as responsive but every ~30s |
| `stopTracking` | `Radar.stopTracking()` | No further `LOCATION` entries |
| `getContext` | `Radar.getContext { … }` | `RESULT` (or `ERROR`) entry containing geofences/place/country |
| `mockTracking` | NYC origin → destination, 3 steps, 3s interval | 3× `RESULT` entries with location/events/user; auto-completes any active trip on the third step |

### Trips panel

| Button | Notes |
|---|---|
| `startTrip` | externalId 300, destination geofence tag `a`/external id `a`, mode car |
| `startTrip (startTracking: false)` | externalId 301, destination tag `store`/123 |
| `startTrip (with tracking options)` | Unique externalId, destination tag `trip_activity`/`trip12345`, started with `.presetContinuous` |
| `startTrip (with startTrackingAfter)` | externalId 303, continuous tracking starts 180s in the future |
| `completeTrip` | `Radar.completeTrip()` |

For multi-leg trips, leg-status changes, and live-reordering, use the **Map tab** instead — see [Map tab](#map-tab).

Trip lifecycle also drives `TripLiveActivityManager` — see "Live Activities" below.

### Verified panel

| Button | SDK call |
|---|---|
| `startTrackingVerified` | `Radar.startTrackingVerified(interval: 60, beacons: false)` |
| `stopTrackingVerified` | `Radar.stopTrackingVerified()` |
| `getVerifiedLocationToken` | Returns a one-shot token; logs `dictionaryValue()` to the `RESULT` detail |
| `trackVerified` | Same payload shape as the token call |

### Search & Geocoding panel

`searchPlaces` (chains=mcdonalds, US), `searchGeofences`, `geocode("20 jay st brooklyn")` × 2 variants, `reverseGeocode` × 4 variants, `ipGeocode`, `validateAddress` × 2 (street+number, label), `autocomplete("brooklyn")` × 3 variants, `getDistance` (foot+car), `getMatrix` (2x2). All log `RESULT`/`ERROR` with formatted detail.

### Notifications panel

| Button | Behavior |
|---|---|
| `test notification` | Schedules a local notification with category `example` |
| `show notification permissions` | Logs `RESULT` with all five settings (alert/badge/lockscreen/sound/notifcenter) + authorization |
| `list pending requests` | Logs `RESULT` with pending notification identifiers |
| `remove first notification (simulate sent)` | Removes one pending request |

### IAM & Conversions panel

| Button | Behavior |
|---|---|
| `iam` | Renders an in-app message via `Radar.showInAppMessage(...)` |
| `logConversion` | `Radar.logConversion(name: "conversion_event", metadata: ["data": "test"])` → logs `RESULT`/`ERROR` with the conversion event |

## Tests tab — settings catalog (gear icon → `TestsSettingsView`)

### Presets section

- A grid of preset chips (see Presets section below). Tap to apply.
- Status caption: shows the active preset's `summary`, or "No preset active — manual identity in effect."
- **Active tracking options** disclosure (collapsed by default): every field on the currently-effective `RadarTrackingOptions`. Source: `SettingsStore.currentTrackingFields`.
- **SDK configuration** disclosure (collapsed by default): every field on the cached `RadarSdkConfiguration`. Source: `SettingsStore.currentSdkConfigFields`. Shows `"No SDK config fetched yet"` when `RadarSdkConfiguration.current()` is nil.

### Identity section

| Field | Behavior |
|---|---|
| User ID | `FieldEditor` commit-on-submit; press Return to write through to `Radar.setUserId(_:)`. The X clear button writes through immediately |
| Description | Same shape, writes to `Radar.setDescription(_:)` |
| Metadata | Read-only display (sorted `key=value` pairs). Editing UI is a known gap |

### Tracking section

Read-only snapshots, refreshed by the section's Refresh button (which calls `settingsStore.refresh()`).

| Row | Source |
|---|---|
| Status | `Radar.isTracking()` → "On"/"Off" |
| Source | `Radar.isUsingRemoteTrackingOptions()` → "Remote (server)" / "Local" |
| Configured | `summarize(Radar.getTrackingOptions(), remote:)` → "Continuous" / "Responsive" / "Efficient" / "Custom (Xs/Ys)" / "Server (Xs/Ys)" |

### Permissions section

| Row | Status display | Action button |
|---|---|---|
| Location | `CLAuthorizationStatus.displayName`, color-coded | Request → progressive escalation; Open Settings when denied/restricted |
| Notifications | `UNAuthorizationStatus.displayName`, color-coded | Request → triggers OS prompt; Open Settings when denied |
| Motion | "Status not exposed by OS" (gray) | Request → triggers OS prompt via the SDK |

The section's Refresh button re-polls notification status (location is live via the delegate).

## Presets

Defined in `Example/Example/Services/TestPreset.swift`. Applying a preset writes identity, optionally calls `Radar.startTracking` or `Radar.stopTracking`, and refreshes snapshots.

| Preset | userId | metadata | Tracking action |
|---|---|---|---|
| Default | nil | `[:]` | `Radar.stopTracking()` |
| Continuous | `"test-continuous"` | `["preset": "continuous"]` | `startTracking(.presetContinuous)` |
| Responsive | `"test-responsive"` | `["preset": "responsive"]` | `startTracking(.presetResponsive)` |
| Efficient | `"test-efficient"` | `["preset": "efficient"]` | `startTracking(.presetEfficient)` |

A manual edit to userId/description/metadata clears `activePresetId` (drops the chip highlight).

## Map tab

The Map tab is the home of the interactive trip flow. It serves three roles:

1. **Layered visualization** of SDK-relevant geo state (monitored regions, synced cache, nearby geofences/places, etc.).
2. **Tap-to-build trip flow** — select geofences from the map to assemble a single- or multi-destination trip.
3. **Active-trip control surface** — once a trip is running, the map suppresses unrelated layers and exposes leg-advance / reorder / complete / cancel controls.

Floating controls (top-right): refresh (`arrow.clockwise`) and layers (`square.stack.3d.up.fill`). The layers sheet shows every registered source as a toggle row.

### Source catalog

All sources implement `MapOverlaySource` and live under `MapOverlays/`. Registration happens in `AppDelegate.didFinishLaunchingWithOptions`.

| Source | Trip-mode whitelisted? | Data | Notes |
|---|---|---|---|
| `MonitoredRegionsSource` | No | `CLLocationManager.monitoredRegions` (system-monitored geofences) | |
| `NearbyGeofencesSource` | No | `Radar.searchGeofences(near:radius:)` — server query | Includes geofence metadata for tap-to-select |
| `SyncedRegionSource` | No | `RadarSyncManager.getSynced{Region,Geofences,Places,Beacons}()` — SDK's local sync cache | Geofences here are also tappable |
| `NearbyPlacesSource` | No | `Radar.searchPlaces(near:...)` | |
| `TripGeofencesSource` | Yes | Resolved geofence shapes for the active trip's legs | Per-trip cache keyed by `tag|externalId` |
| `TripDestinationSource` | Yes | `Radar.getTrip()` destination pins | Pin per coordinate-based leg; geofence-based legs get shape only |
| `TripBreadcrumbsSource` | Yes | `TripBuilderStore.tripBreadcrumbs` — polyline + screen-size dot annotations | Dedupes within 10m |
| `TripEventsSource` | Yes | `TripBuilderStore.tripEventMarkers` — pin per captured trip event | Tap a pin for callout with event type + timestamp |

Layer toggles are persisted across launches. The visible region is also persisted, so the map opens where it was last left.

### Trip-mode whitelist semantics

`MapOverlayRegistry.isInTripMode` becomes `true` whenever `TripBuilderStore.activeTrip` is non-nil. While true:

- Sources with `isTripModeWhitelisted == true` render regardless of user toggle state.
- All other sources are hidden, regardless of user toggle state.
- User toggle state is preserved; when the trip ends, regular layers come back exactly as the user left them.

This means nearby/synced geofence shapes auto-suppress during a trip, while trip-specific overlays (shapes, breadcrumbs, events, destination pins) auto-show.

### Tap-to-build trip flow

1. Browse the map with the user's layer toggles active.
2. **Tap any geofence** (nearby or synced) → `TripBuilderStore.proposeHit` stores it as `pendingHit` → a small confirmation card slides in at the bottom showing the geofence name, tag/externalId, and Add to trip / Cancel buttons.
3. Confirming adds the destination to `selectedDestinations`. Tapping an already-selected geofence and confirming removes it.
4. The **builder tray** at the bottom shows the destination list (1, 2, 3 …) and a **Start trip** button. Long-press a row to drag-to-reorder (system gesture); swipe a row left to delete.
5. Tap **Start trip** → `TripBuilderStore.startTrip()` fires the appropriate SDK call (see "TripBuilderStore" above for the single-vs-multi branching).

### Active-trip control surface

Once `activeTrip != nil`, the builder tray is replaced by an active-trip bar:

- **Header**: external id + current trip status, color-coded.
- **Current leg** (multi-leg only): leg index, description, status, plus advance buttons (`→ approaching` / `→ arrived` / `→ completed`). Each calls `Radar.updateCurrentTripLeg(status:)`.
- **Legs disclosure** (multi-leg only): collapsed by default. Expand to see the full leg list with status badges. Pending legs show ↑/↓ arrow buttons that call `Radar.reorderTripLegs(legIds:)`. Disabled at boundaries (first pending leg, last leg) and for non-pending legs.
- **Complete trip** / **Cancel trip** buttons at the bottom.

Map-side, during the active trip:

- Trip-leg geofence shapes color-code by status: current leg orange (thick stroke), pending legs muted blue, completed legs gray dashed, canceled/expired red dashed.
- Breadcrumb dots accumulate as location updates fire.
- Trip-related events drop pins at their occurrence location. Default filter captures only `userStartedTrip` / `userApproachingTripDestination` / `userArrivedAtTripDestination` / `userStoppedTrip`. Reorder actions also produce a pin because the `Radar.reorderTripLegs` completion handler force-captures its events.

When the trip ends (complete / cancel / server-driven stop), the bar disappears, all trip-overlays clear, and the user's regular layer toggles re-render.

### Cold-start mid-trip

`AppDelegate.didFinishLaunchingWithOptions` calls `tripBuilderStore.refreshActiveTrip()` at launch. If a trip was running when the app was killed, the bar reappears immediately and trip-mode kicks in.

### Beacons

There is no public `Radar.searchBeacons(...)` API. Synced beacons surface via `SyncedRegionSource`. Live-ranged beacons would require a separate source subscribing to `RadarUser.beacons` updates.

## Console glossary

`LogStream` produces six kinds of `ConsoleEntry`. Filter chips in the Logs tab map to subsets:

| Kind | Source | Icon | Color | Filter chip |
|---|---|---|---|---|
| `.action` | `ActionButton` taps (auto), `LogStream.write(action:)` | `play.fill` | blue | Actions |
| `.result` | `LogStream.write(result:)` from completion handlers, or `.write(status:summary:)` on `.success` | `checkmark.circle` | green | Actions |
| `.event` | `RadarDelegate.didReceiveEvents` | `bolt` | purple | Events |
| `.location` | `RadarDelegate.didUpdateLocation` (synced) and `didUpdateClientLocation` (raw) | `location.fill` | teal | Locations |
| `.log` | `RadarDelegate.didLog` | `text.alignleft` | gray | Logs |
| `.error` | `RadarDelegate.didFail`, completion handlers with non-success status, `LogStream.write(error:)` | `exclamationmark.triangle.fill` | red | Logs |

Tap a row to expand its `detail`. `.action`/`.location` rows often have no detail.

Synced location entries are prefixed `synced  `; client (raw) entries are prefixed `stopped  ` or `moving  ` based on the `stopped` flag.

## Permissions matrix

What's needed for which capability:

| Capability | Location | Notifications | Motion | Notes |
|---|---|---|---|---|
| `trackOnce` | When-in-use minimum | — | — | |
| `startTracking` (any preset) | Always recommended; when-in-use works in foreground | — | Optional (improves activity classification) | |
| Sync events (`syncLocations: .events`) | **Always** | — | — | Required for background events |
| Verified | Always | — | — | iOS 17+ for app attestation flows |
| Notifications panel | — | Authorized | — | "Open Settings" path if denied |
| Live Activities (trip) | — | — | — | iOS 16.2+; auto-managed by `TripLiveActivityManager` based on `RadarUser.trip` |
| Map trip breadcrumbs | When-in-use minimum | — | — | Each location update appends one breadcrumb |

## Live Activities

`TripLiveActivityManager` (iOS 16.2+) starts/updates/ends a Live Activity automatically based on trip state observed via `LogStream` publishers (`didReceiveEvents`, `didUpdateLocation`).

- Started/approaching/arrived → starts or updates activity (started with an existing activity → "in_progress")
- completed/canceled/expired → ends activity with that status

There's no manual control surface; it's a side-effect of trip state. Lifecycle messages flow into the unified console via `logStream` (injected by `AppDelegate` at launch).

## Common test recipes

Quick navigation map for "I want to test X" — execute via the catalogs above.

| To test… | Steps |
|---|---|
| Geofence entry/exit | Settings → Continuous preset → Map tab to confirm geofences are loaded → Simulator location to inside/outside the geofence → wait for `EVENT` entry |
| Single-destination trip (panel API) | Trips panel → `startTrip` → mockTracking (auto-completes on 3rd step) OR explicit `completeTrip` |
| Single-destination trip (map UX) | Map tab → tap a geofence → Add to trip → Start trip → use active-trip bar to advance/complete |
| Multi-leg trip (map UX) | Map tab → tap 2+ geofences in succession → reorder in tray if needed → Start trip → use Legs disclosure to advance/reorder/cancel |
| In-flight leg reorder | Start a multi-leg trip → expand Legs disclosure → tap ↑/↓ on a pending leg → confirm `reorderTripLegs` result in console + map updates |
| Trip cold-restart | Start a trip → kill the app → relaunch → active-trip bar should reappear, trip-mode active, breadcrumbs resume from next update |
| Verified attestation | Verified panel → `startTrackingVerified` then `getVerifiedLocationToken` → inspect `RESULT` detail JSON |
| Identifier handoff | Settings → set userId → trigger `trackOnce` → confirm `RESULT`/`LOCATION` reflects the new id |
| Background event detection | Settings → Continuous preset → grant Always location → background app → use Simulator location simulation → wait for `EVENT` |
| SDK config inspection | Settings → expand "SDK configuration" disclosure |
| Active tracking options inspection | Settings → expand "Active tracking options" disclosure |

## Extending the app

### Add a new test action

1. Pick the appropriate panel under `Example/Example/Panels/`.
2. Add an `ActionButton(...)` inside the `TogglePanel` body.
3. The action closure should: invoke the SDK, then `logStream.write(...)` for the result.
4. `ActionButton` auto-logs the tap; you only need to log the result.

### Add a new panel

1. New file in `Panels/` matching the existing shape (`@EnvironmentObject var logStream: LogStream`, body wraps everything in a `TogglePanel`).
2. Add the panel to `TestsView.body`'s `VStack` in the desired order.
3. Default `initiallyExpanded: false` unless it's central enough to warrant always being open (Tracking is the only one that's expanded by default).

### Add a new preset

1. Add a `static let` extension on `TestPreset` (file: `Services/TestPreset.swift`).
2. Append it to `TestPreset.all` in display order.
3. The chip will appear in the Presets section with no further wiring.

### Add a new map source

1. New file in `MapOverlays/` implementing `MapOverlaySource` — provide `id`, `name`, `icon`, and `loadOverlays(near:span:)`. Optionally `renderer(for:)` and `view(for:in:)`.
2. If the source should keep rendering during an active trip (e.g., it's trip-specific), override `var isTripModeWhitelisted: Bool { true }`. Default is `false` (suppressed during trips).
3. If the source's data changes between map pans (e.g., subscription-driven), have its owning store call `MapOverlayRegistry.refreshSource("yourId")` whenever the underlying data changes. The registry will re-aggregate and SwiftUI will re-render.
4. Register it in `AppDelegate.didFinishLaunchingWithOptions`: `mapOverlayRegistry.register(YourSource())`. Registration order is also rendering z-order — last registered renders on top.
5. The toggle row in the layer picker shows up automatically.

### Add a new SDK setting display row

1. In `SettingsStore`'s `fields(from: RadarTrackingOptions)` or `fields(from: RadarSdkConfiguration)`, append a `TrackingField`.
2. Use the `.bool / .interval / .meters / .text` constructors to keep formatting consistent.

### Subscribe to SDK delegate callbacks from a new consumer

`Radar.setDelegate(_:)` accepts only one delegate, and `LogStream` claims it. Your new consumer should subscribe to `LogStream.didReceiveEventsPublisher` or `didUpdateLocationPublisher` (both `PassthroughSubject`) — see `TripBuilderStore.bind(logStream:registry:)` for a worked example.

### Extend the map-driven trip flow

State lives in `TripBuilderStore` (selection + visualization). To plumb a new piece of trip-related data onto the map:

1. Add a `@Published` property on `TripBuilderStore`.
2. Subscribe to whatever publisher updates it (in `bind(...)`), and clear it in `clearTripVisualization()`.
3. Create a new trip-mode-whitelisted `MapOverlaySource` that reads the property.
4. Call `registry.refreshSource("yourId")` from the store whenever the property changes, so the map re-renders without waiting for a pan.
5. Register the source in `AppDelegate`.

## Known gaps

- **Metadata editing UI** — `Identity > Metadata` is read-only. Setting metadata currently only happens via presets. Wiring a small key/value editor here is on the backlog.
- **Publishable key override UI** — `SettingsStore.publishableKeyOverride` exists and is honored on launch, but no UI surfaces it. Override by editing UserDefaults if needed.
- **Live-refresh hook for non-trip map sources** — sources without `isTripModeWhitelisted` only refresh on map pan or the manual refresh button. Trip-mode sources refresh automatically via the store's event/location subscriptions.
- **iOS 14 deployment target compromises** — `FieldEditor` lacks focus-loss commit (Return key only) because `@FocusState`/`onSubmit` require iOS 15+. Bump the example's deployment target to iOS 15+ to clean this up.
- **Ranged-beacons map source** — no public `Radar.searchBeacons(...)` API exists. Synced beacons surface via `SyncedRegionSource` only.
- **TripGeofencesSource search radius** — geofence shapes are resolved via `Radar.searchGeofences(near: mapCenter, radius: 10km, tags: [legTag])`. Trip legs far from the map's current center may not resolve until you pan toward them. Once resolved, the per-trip cache persists for the trip's lifetime.
- **No leg-number labels on geofence-based legs** — `TripDestinationSource` only renders pins for coordinate-based legs. Geofence-based legs are visible only as their shape; the active-trip bar's "Leg N of M" indicator is the only leg-order label.
- **API spam for unfindable geofences** — `TripGeofencesSource` re-attempts unresolved tags on every refresh. If the user pans far from a trip's geofences (and never pans back), expect one `searchGeofences` call per pan. Acceptable for an example app; cap if it becomes noisy.

## Code organization

Example/Example/
├── AppDelegate.swift            # Lifecycle, SDK init, store wiring, source registration
├── MainView.swift               # TabView shell
├── MapView.swift                # Map tab — MKMapView wrapper, builder tray, active-trip bar
├── TestsView.swift              # Tests tab — header + recent activity + 6 panels
├── TestsSettingsView.swift      # Settings sheet behind the gear icon
├── LogsView.swift               # Logs/Debug tab — console timeline
├── MyIAMDelegate.swift          # In-app message delegate
├── TripLiveActivityManager.swift
├── Utils.swift
│
├── Components/                  # Reusable UI primitives
│   ├── ActionButton.swift       # Auto-logs taps; 3 styles (primary/secondary/destructive)
│   ├── ControlRow.swift         # Settings-cell-style labeled row
│   ├── FieldEditor.swift        # Editable text field with clear button
│   ├── TogglePanel.swift        # Collapsible section
│   └── ConsoleEntry+UI.swift    # SwiftUI extensions on ConsoleEntry.Kind
│
├── Panels/                      # Tests-tab content
│   ├── TrackingPanel.swift
│   ├── TripsPanel.swift
│   ├── VerifiedPanel.swift
│   ├── SearchPanel.swift
│   ├── NotificationsPanel.swift
│   └── MessagingPanel.swift
│
├── Services/                    # Stateful, observable bridges
│   ├── LogStream.swift          # RadarDelegate + console source-of-truth
│   ├── SettingsStore.swift      # SDK-backed identity + tracking + field breakdowns
│   ├── PermissionsStore.swift   # CLAuthorizationStatus + UNAuthorizationStatus
│   ├── TripBuilderStore.swift   # Map-driven trip selection + active-trip mirror
│   └── TestPreset.swift         # Bundled tracking presets
│
└── MapOverlays/                 # Map source plugins
    ├── MapOverlaySource.swift   # Protocol + bundle struct + trip-mode whitelist
    ├── MapOverlayRegistry.swift # Source registry, enabled-state, refresh, trip-mode
    ├── GeofenceOverlay.swift    # Common protocol for tappable geofence overlays
    ├── MonitoredRegionsSource.swift
    ├── NearbyGeofencesSource.swift
    ├── NearbyPlacesSource.swift
    ├── SyncedRegionSource.swift
    ├── TripGeofencesSource.swift
    ├── TripDestinationSource.swift
    ├── TripBreadcrumbsSource.swift
    └── TripEventsSource.swift


## Conventions

- New code is Swift only (matches root `AGENTS.md`).
- Service classes go in `Services/`; UI-bearing reusable widgets in `Components/`; tab-specific UI sub-units in `Panels/` (Tests tab) or alongside their parent view; map plugins in `MapOverlays/`.
- One `ObservableObject` per concern. Don't merge stores; cross-store coordination lives in `AppDelegate` or in store-to-store `bind(...)` methods.
- All console output flows through `LogStream`. Don't `print()`; use `logStream.write(...)`.
- All SDK delegate callbacks must go through `LogStream`. Don't call `Radar.setDelegate(_:)` from anywhere else.
- Trip lifecycle state lives in `TripBuilderStore`. New trip-related features should hang off that store rather than introducing parallel mirrors of `Radar.getTrip()`.
