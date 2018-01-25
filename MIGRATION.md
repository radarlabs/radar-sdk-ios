# Migration guides

## 1.2.x to 1.3.0

`userId` on `RadarUser` is now nullable and `reidentifyUserWithOldUserId:` has been removed. To reidentify a user, simply call `setUserId:` with the new `userId`.

No other code changes are required to upgrade from 1.2.x to 1.3.0.

## 1.1.x to 1.2.0

No code changes are required to upgrade from 1.1.x to 1.2.0. However, project metadata changes are required.

To prompt for background location permissions on iOS 11, you must add the new `NSLocationAlwaysAndWhenInUseUsageDescription` property to your `Info.plist`:

```xml
<!-- new property -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Your iOS 11 and higher background location usage description goes here.</string>

<!-- old properties -->
<key>NSLocationAlwaysUsageDescription</key>
<string>Your iOS 10 and lower background location usage description goes here.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your foreground location usage description goes here.</string>
```

You should keep the `NSLocationAlwaysUsageDescription` and `NSLocationWhenInUseUsageDescription` properties for backcompatibility.

## 1.0.x to 1.1.0

### Objective-C

1.0.x

```objc
[Radar initWithKey:publishableKey];

[Radar startTrackingWithUserId:userId description:description];

[Radar trackOnceWithUserId:userId description];
```

1.1.0

```objc
[Radar initializeWithPublishableKey:publishableKey];

[Radar setUserId:userId];
[Radar setDescription:description];

[Radar startTracking];

[Radar trackOnceWithCompletionHandler:^(RadarStatus status, CLLocation *location, NSArray<RadarEvent *> *events, RadarUser *user) {
  // do something with status, location, events, user
}];
```

### Swift

1.0.x

```swift
Radar.initWithKey(publishableKey)

Radar.startTracking(withUserId: userId, description: description)

Radar.trackOnce(withUserId: userId, description: description)
```

1.1.0

```swift
Radar.initialize(publishableKey: publishableKey)

Radar.setUserId(userId)
Radar.setDescription(description)

Radar.startTracking()

Radar.trackOnce(completionHandler: { (status, location, events, user) in
  // do something with status, location, events, user
})
```
