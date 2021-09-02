# Migration guides

## 3.1.x to 3.2.x

- The SDK is now distributed as a `.xcframework` file instead of a `.framework` file.
- A few methods have been renamed to avoid false positive App Store rejections for private APIs.
  - On `RadarTrackingOptions`, presets now begin with `preset`. `RadarTrackingOptions.continuous` is now `RadarTrackingOptions.presetContinuous`, `RadarTrackingOptions.responsive` is now `RadarTrackingOptions.presetResponsive`, and `RadarTrackingOptions.efficient` is now `RadarTrackingOptions.presetEfficient`.
  - On `RadarTrackingOptions`, `trackingOptions.sync` is now `trackingOptions.syncLocations`.
  - On `RadarTripOptions`, `initWithExternalId:` is now `initWithExternalId:destinationGeofenceTag:destinationGeofenceExternalId:`.
  - On `RadarBeacon`, `RadarGeofence`, and `RadarUser`, `_description` is now `__description`.
  - On `RadarPolygonGeometry`, `coordinates` is now `_coordinates`.
  - On `Radar`, `stringForSource:` is now `stringForLocationSource:`.
- `RadarTripCompletionHandler` now returns `trip` and `events` on calls to `Radar.startTrip()`, `Radar.updateTrip()`, `Radar.completeTrip()`, and `Radar.cancelTrip()`.
- On `RadarDelegate`, `user` is now optional on `didReceiveEvents:user:`. `user` will be `nil` when events are delivered from calls to `Radar.startTrip()`, `Radar.updateTrip()`, `Radar.completeTrip()`, and `Radar.cancelTrip()`.

```swift
// 3.2.x

// presets now begin with `preset`
Radar.startTracking(RadarTrackingOptions.presetContinuous)
Radar.startTracking(RadarTrackingOptions.presetResponsive)
Radar.startTracking(RadarTrackingOptions.presetEfficient)

// `RadarTripCompletionHandler` now returns `trip` and `events`
Radar.startTrip(options: options) { status, trip, events in
  
}

// `user` is now optional
func didReceiveEvents(_ events: [RadarEvent], user: RadarUser?) {
  
}
```

```swift
// 3.1.x

Radar.startTracking(RadarTrackingOptions.continuous)
Radar.startTracking(RadarTrackingOptions.responsive)
Radar.startTracking(RadarTrackingOptions.efficient)

Radar.startTrip(options: options) { status in
  
}

func didReceiveEvents(_ events: [RadarEvent], user: RadarUser) {
  
}
```

## 3.0.x to 3.1.x

- The `Radar.trackOnce(desiredAccuracy:completionHandler:)` method is now `Radar.trackOnce(desiredAccuracy:beacons:completionHandler)`. Use `beacons = true` to range beacons.
- The `Radar.stopTrip()` method has been removed. Call `Radar.completeTrip()` or `Radar.cancelTrip()` instead.

## 2.1.x to 3.0.x

- This update introduces new tracking options and presets. See the [announcement](https://radar.io/blog/open-source-radar-sdk-v3-custom-tracking-options-public-beta), the [background tracking documentation](https://radar.io/documentation/sdk-v3#ios-background), and the [tracking options reference](https://radar.io/documentation/sdk/tracking#ios).
  - If you were using `Radar.startTracking()`, you must choose a preset. v2 default behavior was similar to `Radar.startTracking(RadarTrackingOptions.responsive)`.
  - If you were using `trackingOptions.priority = RadarTrackingPriorityEfficiency`, use the preset `RadarTrackingOptions.efficient` instead.
- The `didUpdateClientLocation:stopped:source:` method is now required in `RadarDelegate`. It tells the delegate that the client's location was updated but not necessarily synced to the server. To receive only server-synced location updates and user state, use `didUpdateLocation:user:` instead.
- The `updateLocation:completionHandler:` method has been renamed to `trackOnceWithLocation:completionHandler:`.
- `adId` collection is now optional. To collect `adId`, call `setAdIdEnabled:`.
- `setPlacesProvider:` has been removed.

```swift
// 3.0.x

Radar.startTracking(RadarTrackingOptions.efficient)

Radar.trackOnce(location, completionHandler)

Radar.setAdIdEnabled(true) // optional
```

```swift
// 2.1.x

let trackingOptions = RadarTrackingOptions()
trackingOptions.priority = .efficiency
Radar.startTracking(trackingOptions)

Radar.updateLocation(location, completionHandler)
```

## 2.0.x to 2.1.x

- This update introduces `startTrackingWithOptions:` to configure advanced tracking options. See https://radar.io/documentation/sdk#ios-background.

## 1.3.x to 2.0.x

- The `requestWhenInUseAuthorization`, `requestAlwaysAuthorization`, and `authorizationStatus` helper methods have been removed. Call the corresponding methods on `CLLocationManager` instead. See https://developer.apple.com/documentation/corelocation/cllocationmanager.
- The `RadarStatusErrorUserId` and `RadarStatusErrorPlaces` enum values have been removed. The SDK now handles these cases gracefully.
- The `setTrackingPriority:` method has been removed.

## 1.2.x to 1.3.x

- `userId` on `RadarUser` is now nullable.
- The `reidentifyUserWithOldUserId:` method has been removed. To reidentify a user, call `setUserId:` with the new `userId` instead.
