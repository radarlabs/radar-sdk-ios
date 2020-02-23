# Migration guides

## 2.1.x to 3.0.x

- This update introduces new tracking options and presets. See the [announcement](https://radar.io/blog/open-source-radar-sdk-v3-custom-tracking-options-public-beta), the [background tracking documentation](https://radar.io/documentation/sdk-v3#ios-background), and the [tracking options documentation](https://radar.io/documentation/sdk/tracking#ios).
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
