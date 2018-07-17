# Migration guides

## 1.3.x to 2.0.x

- The `requestWhenInUseAuthorization`, `requestAlwaysAuthorization`, and `authorizationStatus` helper methods have been removed. Call the corresponding methods on `CLLocationManager` instead. https://developer.apple.com/documentation/corelocation/cllocationmanager
- The `RadarStatusErrorUserId` and `RadarStatusErrorPlaces` enum values have been removed. The SDK now handles these cases gracefully.
- The `setTrackingPriority:` method has been removed.

## 1.2.x to 1.3.x

- `userId` on `RadarUser` is now nullable.
- The `reidentifyUserWithOldUserId:` method has been removed. To reidentify a user, call `setUserId:` with the new `userId` instead.
