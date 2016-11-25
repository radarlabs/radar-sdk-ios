# Migration guides

## 1.0.x to 1.1.0

### Objective-C

1.0.x

```objective-c
[Radar initWithKey:publishableKey];

[Radar startTrackingWithUserId:userId description:description];

[Radar trackOnceWithUserId:userId description];
```

1.1.0

```objective-c
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