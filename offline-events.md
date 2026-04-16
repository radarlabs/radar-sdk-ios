## Summary

Introduces `RadarOfflineEventManager` — a client-side system for generating synthetic geofence events and switching tracking options when the device is offline. This is gated by two independent server-controlled flags: `offlineEventGenerationEnabled` (for synthetic events) and `useOfflineRTOUpdates` (for tracking option switching). Also adds `RadarRemoteTrackingOptions` to parse and look up the array of tagged tracking presets sent by the server.

## New SDK Components

**`RadarOfflineEventManager`** — Generates synthetic geofence entry/exit events by evaluating the device's location against locally cached geofence data from the sync region. On track failure, fires events via the delegate callback and optionally switches tracking options based on geofence tag matching. Builds a synthetic `RadarUser` using the cached user identity from `RadarState`.

**`RadarRemoteTrackingOptions`** — Parses the `remoteTrackingOptions` array from `sdkConfiguration`. Each entry has a `type` (`default`, `onTrip`, `inGeofence`), a `trackingOptions` preset, and optional `geofenceTags`. Provides lookup helpers to retrieve tracking options or geofence tags by type.

**`RadarOfflineEventManager.h`** — Obj-C header exposing `RadarOfflineEventManager` methods to `RadarAPIClient.m`, replacing the previous `NSClassFromString`/`performSelector` pattern with direct method calls.


## How It Works

1. **Server sends configuration**: `offlineEventGenerationEnabled` and `useOfflineRTOUpdates` arrive in `sdkConfiguration`. When `useOfflineRTOUpdates` is true, the server also sends a `remoteTrackingOptions` array with tagged presets. These are parsed by `RadarSdkConfiguration` and `RadarRemoteTrackingOptions`.

2. **Track failure triggers offline logic** (`RadarAPIClient.m`): When a track call fails, the API client calls `handleTrackFailure:` (gated by `offlineEventGenerationEnabled`) and `updateTrackingOptionsFor:` (gated by `useOfflineRTOUpdates`). These are now direct method calls via the new Obj-C header.

3. **Event generation** (`generateEvents`): Compares the current location against synced geofences from `RadarSyncManager`. Detects entries and exits relative to the previously known geofence set. Builds synthetic `RadarEvent` objects with `metadata: {offline: true}` and delivers them via `didReceiveEvents` delegate callback.

4. **Synthetic user** (`buildSyntheticUser`): Retrieves the cached `RadarUser` from `RadarState` (persisted on every successful track) and constructs a new user with updated location and geofences, while preserving identity fields (`_id`, `userId`, `deviceId`, `description`, `metadata`).

5. **Tracking option switching** (`updateTrackingOptions`): Checks if the user is in a geofence whose tag matches the `inGeofence` remote tracking option's `geofenceTags`. If matched, ramps up to in-geofence tracking options. Otherwise falls back to on-trip (if active) or default tracking options.

6. **Sync region re-fetch** (`RadarLocationManager.m`): When `offlineEventGenerationEnabled` is true, proactively re-fetches the sync region if the device moves outside or near the boundary of the current synced region, ensuring fresh geofence data for offline event evaluation.

7. **User caching** (`RadarState`): Added `setRadarUser:`/`radarUser` to persist the full `RadarUser` to `NSUserDefaults` on every successful track response. Exposed to Swift via the `RadarSwiftBridge` protocol.

## Test Coverage

Unit tests in `RadarOfflineEventManagerTests.swift` covering:
- `handleTrackFailure` gating by `offlineEventGenerationEnabled`
- `updateTrackingOptions` geofence tag matching and fallback logic
- `generateEvents` entry/exit detection and empty-result cases
- `reset` clearing offline geofence state