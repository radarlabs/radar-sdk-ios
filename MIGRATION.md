# Migration guides

## 2.1.x to 3.0.x

- The `updateLocation:completionHandler:` method has been renamed to `trackOnceWithLocation:completionHandler:`.
- This update introduces new tracking options and presets. See https://radar.io/blog/open-source-radar-sdk-v3-custom-tracking-options-public-beta. If you were using `trackingOptions.priority = RadarTrackingPriorityEfficiency`, use the preset `RadarTrackingOptions.efficient` instead.
- Call methods for `userId` and `metadata` getters and setters.
- `adId` collection is now optional. To collect `adId`, call `setAdIdEnabled:`.
- `setPlacesProvider:` has been removed.

```swift
// 3.0.x
Radar.trackOnce(location, completionHandler)

Radar.startTracking(RadarTrackingOptions.efficient)

Radar.setUserId(userId)

Radar.setAdIdEnabled(true) // optional

// 2.1.x
Radar.updateLocation(location, completionHandler)

let trackingOptions = RadarTrackingOptions()
trackingOptions.priority = .efficiency
Radar.startTracking(trackingOptions)

Radar.userId = userId
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
