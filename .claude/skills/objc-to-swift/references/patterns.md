# radar-sdk-ios ObjC → Swift migration patterns

Detailed reference for the `objc-to-swift` skill. Read the section for the strategy you
picked; skim the Gotchas before you write code and again before you open the PR.

All paths are relative to the radar-sdk-ios repo root unless noted.

---

## 1. Architecture you're migrating inside

`RadarSDK` is a **mixed ObjC/Swift framework** (`DEFINES_MODULE = YES`,
`CLANG_ENABLE_MODULES = YES`, `SWIFT_VERSION = 6.0`). Two header-visibility tiers drive
almost every migration decision:

- **Public headers** live in `RadarSDK/Include/` (`publicHeadersPath: "Include"` in
  `Package.swift`). They are in the Swift module, so Swift can call them directly
  (`RadarBeacon`, `RadarGeofence`, `RadarTrackingOptions`, `Radar`, `RadarUser`, …).
- **Project-internal headers** live in `RadarSDK/` root (`RadarLocationManager.h`,
  `RadarState.h`, `RadarNotificationHelper.h`, every `*+Internal.h`). They are **not** in
  the Swift module, so **Swift cannot see them**.

**The framework target has no bridging header** (frameworks can't use one). So the two
directions are solved differently:

- **ObjC → Swift**: the compiler generates `RadarSDK-Swift.h`. ObjC files import it behind a
  guard (the framework-build path differs from the consumer path):
  ```objc
  #if __has_include(<RadarSDK/RadarSDK-Swift.h>)
  #import <RadarSDK/RadarSDK-Swift.h>
  #elif __has_include("RadarSDK-Swift.h")
  #import "RadarSDK-Swift.h"
  #endif
  ```
  Only `public`/`open` `@objc` classes land in that header; `internal @objc` classes are
  callable from ObjC **in the same module** but do **not** appear in the installed header.
- **Swift → internal ObjC**: Swift can't import internal `.h`s, so there is a hand-written
  **bridge protocol**, `RadarSwift.bridge` (`RadarSDK/RadarSwiftBridge.{swift,h,m}`):
  ```swift
  @objc protocol RadarSwiftBridgeProtocol {
      func geofenceIds() -> [String]?
      func lastLocation() -> CLLocation?
      func createEvent(dict: [String: Any]) -> RadarEvent?
      // …must match the ObjC side by hand
  }
  @objc(RadarSwift) @objcMembers
  class RadarSwift: NSObject {
      nonisolated(unsafe) static var bridge: RadarSwiftBridgeProtocol?
  }
  ```
  The ObjC `RadarSwiftBridge.m` implements it by forwarding to the internal classes
  (`[RadarState geofenceIds]`, `[RadarReplayBuffer sharedInstance]`, …). Swift callers do
  `RadarSwift.bridge?.geofenceIds()`. If your ported Swift needs an internal ObjC API,
  **add a method to this protocol** rather than trying to import the header.

---

## 2. The five strategies (pick one)

### Decision table

| Situation | Strategy |
|---|---|
| Leaf data model with `initWithObject:`/`dictionaryValue` JSON (de)serialization | **D** value-type struct (most common) |
| Small/self-contained class ObjC callers construct/use directly, can convert in one shot | **A** full `@objc` replacement |
| Swift twin must be callable from ObjC while a same-named ObjC class still exists | **C** `_Swift`-suffixed twin |
| Swift-only helper, ObjC doesn't need it (reach old behavior via `RadarSwift.bridge`) | **E** no-`@objc` twin |
| Large, stateful class (a manager) that can't convert at once | **B** per-method seam behind a flag |

### Strategy D — pure-Swift value type (the common leaf path)

A `Codable, Sendable` struct named `RadarFooSwift`, introduced **alongside** the legacy
`.m` (strangler), consumed by Swift code first. Exemplar: `RadarSDK/RadarBeacon.swift`.

```swift
struct RadarBeaconSwift: Codable, Sendable {
    let id: String
    let uuid: String
    // …
    enum CodingKeys: String, CodingKey {
        case id = "_id"   // map JSON keys that differ from Swift names
        case uuid
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""   // lenient
        uuid = try c.decode(String.self, forKey: .uuid)              // required
    }
    init(id: String, uuid: String) { self.id = id; self.uuid = uuid } // memberwise for callers/tests
}
```

Rules of thumb: `decodeIfPresent(...) ?? default` for optional/lenient fields, `decode`
for required ones; `throw DecodingError.dataCorruptedError(...)` only for genuinely
unsupported values; keep the ObjC `.m`/`.h` on disk until every consumer is Swift.

### Strategy A — full-file `@objc` replacement (reclaim the ObjC name)

`@objc(RadarFoo) @objcMembers class RadarFoo: NSObject`. Delete the `.m`, **keep the `.h`**
(ObjC still `#import`s it; the internal Swift class stays out of `RadarSDK-Swift.h`, so
there's no duplicate-`@interface` clash). Exemplars: `RadarReplay.swift`,
`RadarReplayBuffer.swift`, `RadarUtils.swift`, `RadarSettings.swift`, `RadarLogger.swift`.

```swift
@objc(RadarReplay)
@objcMembers
internal class RadarReplay: NSObject, NSSecureCoding {
    @objc(initWithParams:) public init(params: [AnyHashable: Any]) { … }
    @objc(arrayForReplays:) public static func arrayForReplays(_ r: [RadarReplay]?) -> [[AnyHashable: Any]]? { … }
    public static var supportsSecureCoding: Bool { true }
}
```

- Use explicit `@objc(selectorWithColons:)` to preserve the exact ObjC selector.
- If a value persists via `NSSecureCoding` (e.g. `radar-replays` in `UserDefaults`),
  **keep `@objc(RadarFoo)` identical** so already-archived data still decodes after upgrade.
- Methods that become `async` in Swift can't be called synchronously from ObjC. Park those
  on a `RadarFooDeprecated : RadarFoo` subclass so ObjC callers use
  `[RadarFooDeprecated bar]` (see `RadarUtils.h`, `RadarUtilsDeprecated`).

### Strategy B — per-method seam behind a flag (large stateful classes)

The `RadarLocationManager` pattern. Port one method at a time; both implementations
coexist behind `useSwiftLocationManager` until the Swift side is trusted in production.
Exemplars: `RadarSDK/RadarLocationManager+Swift.swift`, `RadarSDK/RadarLocationManagerSwift.h`,
`RadarSDK/RadarLocationManager.m`.

The four moving parts per method:

1. **Swift twin** — a `static` method on a new `@objc(RadarFooSwift)` helper class in
   `RadarFoo+Swift.swift`. It can't extend the ObjC class (internal header not in the
   module), so state it needs is passed as arguments:
   ```swift
   @objc(RadarLocationManagerSwift)
   final class RadarLocationManagerSwift: NSObject {
       @objc static func restartPreviousTrackingOptions() {
           RadarLogger.shared.debug("🦅 Restarting previous tracking options")   // 🦅 = Swift path ran
           // …
       }
       @objc(replaceSyncedBeaconsOnLocationManager:beacons:)
       static func replaceSyncedBeacons(locationManager: CLLocationManager, beacons: [RadarBeacon]?) { … }
   }
   ```
2. **Hand-maintained bridge header** — declare the twin's ObjC face in `RadarFooSwift.h`
   (kept in sync by hand; it's the stable, reviewable contract the `.m` compiles against):
   ```objc
   NS_ASSUME_NONNULL_BEGIN
   @interface RadarLocationManagerSwift : NSObject
   + (void)restartPreviousTrackingOptions;
   + (void)replaceSyncedBeaconsOnLocationManager:(CLLocationManager *)locationManager
                                         beacons:(nullable NSArray<RadarBeacon *> *)beacons;
   @end
   NS_ASSUME_NONNULL_END
   ```
3. **Dispatch guard** — prepend ~5 lines to the ObjC method; leave the ObjC body intact for
   the flag-off path:
   ```objc
   - (void)restartPreviousTrackingOptions {
       if ([RadarSettings sdkConfiguration].useSwiftLocationManager) {
           [RadarLocationManagerSwift restartPreviousTrackingOptions];
           return;
       }
       // …original ObjC body stays here…
   }
   ```
4. **Seam test** — call the Swift twin directly *and* call the ObjC entry point with the
   flag toggled, asserting both reach the same end state (see §6).

Conventions: `...OnLocationManager:` selectors for methods that take the manager; plain
selectors for value-only methods; a `🦅` prefix on every ported log line (the smoke-test
tell); mirror any needed ObjC constants as `private static let` and note "kept in sync by
hand until cutover." When a method's Swift port has soaked in production, delete the ObjC
body + guard. When the `.m` is empty, the class graduates to Strategy A/C.

### Strategy C — `_Swift`-suffixed twin (coexist with a same-named ObjC class)

When the Swift class must be **called from ObjC** but an ObjC class of the same name still
exists, expose it under a `_Swift` ObjC name to avoid an in-module symbol clash. Exemplars:
`RadarNotificationHelper.swift` (`@objc(RadarNotificationHelper_Swift) … actor`),
`RadarInAppMessage_Swift`, `RadarDelegateHolder_Swift`.

```swift
@objc(RadarNotificationHelper_Swift) @objcMembers
actor RadarNotificationHelper: NSObject { … }
```
The ObjC header keeps the original `@interface RadarNotificationHelper` **and**
forward-declares the twin's ObjC face (`@interface RadarNotificationHelper_Swift : NSObject
…`). ObjC calls `[[RadarNotificationHelper_Swift shared] …]`. The Swift runtime keeps the
bare name; ObjC sees `_Swift` (`SWIFT_CLASS_NAMED("RadarNotificationHelper")`).

### Strategy E — Swift-only twin, no `@objc`

When ObjC doesn't need the Swift class, omit `@objc` entirely so it never enters
`RadarSDK-Swift.h` (no collision). Exemplar: `RadarSDK/RadarState.swift` — a minimal typed
reimplementation of one concern of the ObjC `RadarState`. Swift code that needs the *old*
`RadarState` behavior routes through `RadarSwift.bridge` instead of touching the ObjC class.

---

## 3. Naming conventions (summary)

| Form | Meaning | Example |
|---|---|---|
| `@objc(RadarFoo)` class, no suffix | Full conversion, reclaims the ObjC name | `RadarReplay`, `RadarUtils` |
| `struct RadarFooSwift` (no `@objc`) | Pure-Swift value type (Strategy D) | `RadarBeaconSwift` |
| `@objc(RadarFoo_Swift)` | ObjC-visible twin next to a same-named ObjC class | `RadarNotificationHelper_Swift` |
| `@objc(RadarFooSwift)` helper | Seam helper holding static twins (Strategy B) | `RadarLocationManagerSwift` |
| class, no `@objc` at all | Swift-only twin, ObjC unaffected | `RadarState` (Swift) |
| `RadarFooDeprecated : RadarFoo` | Holds methods that became `async` in Swift | `RadarUtilsDeprecated` |

---

## 4. `project.pbxproj` mechanics

A `.swift` source file appears in **three** places (Xcode-generated GUIDs):
1. **`PBXBuildFile`** — `… /* RadarFoo.swift in Sources */ = {isa = PBXBuildFile; fileRef = …; };`
2. **`PBXFileReference`** — `… /* RadarFoo.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RadarFoo.swift; sourceTree = "<group>"; };`
3. **`PBXGroup`** (navigator) **and** the **`PBXSourcesBuildPhase`** (compile) list.

- **Adding** a `.swift`: add all three (build file, file ref, group + Sources phase entry).
- **Removing** a `.m` (full conversion): delete its `PBXBuildFile`, `PBXFileReference`,
  group entry, and `PBXSourcesBuildPhase` entry.
- **`.h` files** live in the **`PBXHeadersBuildPhase`**, not Sources. **Keep the `.h`** while
  any ObjC still `#import`s it; only remove it once nothing does.
- New Swift **test** files get the same three entries but in the **test target's** Sources
  phase.
- Verify the file didn't get corrupted: `plutil -lint RadarSDK.xcodeproj/project.pbxproj`.

Prefer editing the pbxproj via Xcode when practical; if editing by hand, copy the exact
shape of an existing sibling entry and reuse a unique 24-hex GUID.

---

## 5. Gotcha catalog (each has bitten a real PR)

- **In-module name collision** — a Swift `@objc` class shadows a same-named ObjC class in
  the module → build/runtime confusion. Fix: `@objc(RadarFoo_Swift)` (Strategy C) or drop
  `@objc` (Strategy E). [[swift-objc-name-collision-blocks-ports]]
- **Swift can't see internal ObjC headers** — internal `.h`s aren't in the module. Fix:
  add the API to `RadarSwiftBridgeProtocol` (`RadarSwift.bridge`), or, for a manager seam,
  pass the needed state in as arguments. Don't reimplement legacy helpers ad hoc — prefer
  converging on the V2 Swift path (as `replaceSyncedGeofences` did onto
  `RadarNotificationHelper.shared`).
- **`async` overload ambiguity** — two ObjC completion-handler methods that map to the same
  Swift name synthesize two `async` overloads differing only by `throws`, making every
  `await` call site ambiguous and un-compilable. Fix: `NS_SWIFT_DISABLE_ASYNC` on the new
  method; add a regression test that fails to build on ambiguity. (Shipped-broken in 3.34.1.)
- **`String` → `Int` silent fallback** — `RadarBeacon.major/.minor` are `String`.
  `Int(beacon.major) ?? 0` silently monitors a bogus `0/0` region. Fix:
  `guard let major = Int(beacon.major) else { log; skip }`.
- **App-group `UserDefaults` split** — if the Swift twin writes via an app-group-aware
  suite but the ObjC reader uses `standardUserDefaults` (or vice versa), reads/writes hit
  different stores when the flag is on. Fix: **move the getter and setter together**;
  route both through the same suite (`RadarUserDefaults`).
- **Vacuous seam test** — asserting only on state the twin always clears passes even if the
  real work never ran. Fix: assert on the actual outcome (`RadarSettings.tracking`, synced
  regions), install mocks, and reset shared state in a shared helper.
- **Hand-mirrored constants drift** — identifier prefixes duplicated ObjC↔Swift during a
  seam. Keep them as `private static let`, comment "kept in sync by hand until cutover,"
  and delete the ObjC copy at cutover.
- **Actor-executor SIGTRAP** — a `@globalActor`/`actor` class exposed to ObjC crashes with
  "Incorrect actor executor assumption" when ObjC calls an actor-isolated `shared`/`init`
  synchronously off-executor. Fix: make the singleton accessor and initializer
  `nonisolated` (`public nonisolated static let shared`, `nonisolated override init()`),
  init only from `nonisolated`/`Sendable` expressions, mark init-only-written stored props
  `nonisolated(unsafe)`; keep the genuinely async methods actor-isolated. Exemplar:
  `RadarSDK/RadarIndoors.swift`. [[actor-isolated-shared-crashes-from-objc]]
- **Actor completion on the wrong executor** — when an actor's async completion fires on a
  background executor but downstream touches `@MainActor` state, marshal back:
  `[RadarUtilsDeprecated runOnMainThread:^{ completionHandler(...); }]`.

---

## 6. Testing conventions

- **Swift Testing** for new suites (`@Suite`, `@Test`, `#expect`); `@testable import RadarSDK`
  to reach `internal` types. Older suites are XCTest.
- **Dependency injection** is the dominant pattern: migrated classes take collaborators with
  production defaults (`notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()`);
  tests pass mocks (`MockNotificationCenter`, `MockRadarState : RadarState, @unchecked Sendable`).
- **Seam tests** exercise both paths — call the Swift twin directly *and* call the ObjC
  entry point with the flag toggled via `RadarSdkConfiguration(dict: ["useSwiftLocationManager": true/false])`,
  asserting both reach the same end state. Helpers: `RadarLocationManagerSwiftTestHelpers`
  (centralized `clearState()`). Exemplar: `RadarSDKTests/RadarLocationManagerSwiftSeamTests.swift`.
- **Serialized suites** — suites that mutate global `RadarSettings`/`UserDefaults` state are
  nested under a `@Suite(.serialized)` parent (e.g. `RadarSerializedTests`) so they don't race.
  [[wall-clock-race-test-flakiness]]
- **Test bridging header** — Swift tests reach internal ObjC via
  `RadarSDKTests/RadarSDKTests-Bridging-Header.h`. If a test needs an internal API, a
  `+Internal.h`, or an ObjC mock (`RadarPermissionsHelperMock`, `RadarAPIHelperMock`), add
  the import there.
- `make test-pretty` **skips** `InAppMessageTest`, `RadarSettingsTest`,
  `RadarNotificationHelperTest` (timing-sensitive); run those via `make test-swift`.

---

## 7. Key files to read (by strategy)

- Strategy D value type: `RadarSDK/RadarBeacon.swift`, `RadarSDK/RadarGeofence.swift`
  (associated-value enum + custom `Codable`), `RadarSDK/RadarCoordinate.swift`.
- Strategy A full conversion: `RadarSDK/RadarReplay.swift`, `RadarSDK/RadarUtils.{swift,h}`
  (+ `RadarUtilsDeprecated`).
- Strategy B seam: `RadarSDK/RadarLocationManager+Swift.swift`,
  `RadarSDK/RadarLocationManagerSwift.h`, `RadarSDK/RadarLocationManager.m` (~line 536),
  `RadarSDKTests/RadarLocationManagerSwiftSeamTests.swift`.
- Strategy C/E collisions: `RadarSDK/RadarNotificationHelper.{swift,h}` (`_Swift`),
  `RadarSDK/RadarState.swift` (no `@objc`).
- Interop: `RadarSDK/RadarSwiftBridge.{swift,h,m}`, `Package.swift`.
- Actor gotcha: `RadarSDK/RadarIndoors.swift`.
- Policy: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`.
