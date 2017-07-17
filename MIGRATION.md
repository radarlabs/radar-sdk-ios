# Migration guides

## 1.1.x to 1.2.0

No code changes are required to upgrade from 1.1.x to 1.2.0. However, project metadata changes are required.

To avoid the [blue bar on iOS 11](https://blog.onradar.com/making-sense-of-new-background-location-restrictions-in-ios-11-and-android-o-2c35eaf7af), 1.2.0 does not use the standard location service in the background. This means that the location background mode is no longer required. You should uncheck *Location updates* in the *Background Modes* section of your target's *Capabilities* tab:

![Screenshot](https://raw.githubusercontent.com/radarlabs/radar-sdk-ios/master/Images/0.png)

In addition, to prompt for background location permissions on iOS 11, you must add the new `NSLocationAlwaysAndWhenInUseUsageDescription` property to your `Info.plist`:

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
