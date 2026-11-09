//
//  RadarTraceSpan+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarAPIHelper.h"

@class RadarPreparedFraudPayloadWrapper;

NS_ASSUME_NONNULL_BEGIN

// Declares the internal Swift RadarTraceSpan for Objective-C callers, since internal Swift classes are not emitted
// into RadarSDK-Swift.h. It is the RadarAPIRequestTrace that RadarAPIHelper ends for a traced request.
@interface RadarTraceSpan : NSObject <RadarAPIRequestTrace>

// Starts a new trace with this span as its root, or returns the no-op span if tracing is off.
+ (RadarTraceSpan *)startWithName:(NSString *)name;

// Starts a child span for work inside the SDK. Children of the no-op span are the same no-op span.
- (RadarTraceSpan *)child:(NSString *)name;

// Starts a child span for a request to the Radar API. Send its traceparent with the request.
- (RadarTraceSpan *)clientChild:(NSString *)name;

// The W3C traceparent header for requests made in this span. Nil for the no-op span.
@property (nonatomic, readonly, copy, nullable) NSString *traceparent;

// NO for the no-op span, which ignores attributes and records nothing. Check it before computing attribute values
// that cost more than reading a stored value.
@property (nonatomic, readonly) BOOL isRecording;

// Attribute setters. Ignored on the no-op span and after -endWithStatus:.
- (void)setString:(NSString *)value forKey:(NSString *)key;
- (void)setInteger:(int64_t)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

// Ends the span and records it. Only the first call has an effect.
- (void)endWithStatus:(RadarStatus)status;

@end

// RadarTrackTracing.swift
@interface RadarTraceSpan (Track)

// Attributes of a radar.track_once root. The app state is omitted when called off the main thread.
- (void)recordTrackWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy beacons:(BOOL)beacons;

// Attributes of a radar.track_verified root, with the app state the caller already read on the main thread.
- (void)recordTrackWithDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy beacons:(BOOL)beacons foreground:(BOOL)foreground;

// Whether the app is in the foreground (omitted when called off the main thread), and whether location access is
// precise, for a root that doesn't record the track attributes.
- (void)recordAppContext;

// Set on the root when its track is sent as a replay flush instead.
- (void)markReplayed;

// Ends this span with the track's status, then calls handler. Returns handler unchanged when this span doesn't record.
- (void (^_Nullable)(RadarStatus, CLLocation *_Nullable, NSArray<RadarEvent *> *_Nullable, RadarUser *_Nullable))endingTrackHandler:
    (void (^_Nullable)(RadarStatus, CLLocation *_Nullable, NSArray<RadarEvent *> *_Nullable, RadarUser *_Nullable))handler;

@end

// RadarLocationTracing.swift
@interface RadarTraceSpan (Location)

// Traces getting a location as a radar.location.get child, which starts now and ends before handler runs.
- (void (^)(RadarStatus, CLLocation *_Nullable, BOOL))tracingLocationHandler:(void (^)(RadarStatus, CLLocation *_Nullable, BOOL))handler;

// The location's age and accuracy.
- (void)recordLocationQuality:(CLLocation *)location;

@end

// RadarBeaconTracing.swift
@interface RadarTraceSpan (Beacon)

// continuous or search.
- (void)setBeaconSource:(NSString *)source;

// Traces one-shot ranging as a radar.beacon.range child, which starts now and ends before handler runs. mode is uuids or
// beacons.
- (void (^)(RadarStatus, NSArray<RadarBeacon *> *_Nullable))tracingBeaconHandler:(void (^)(RadarStatus, NSArray<RadarBeacon *> *_Nullable))handler
                                                       mode:(NSString *)mode;

@end

// RadarVerificationTracing.swift
@interface RadarTraceSpan (Verification)

// Whether trackVerified retried its config request on the secondary verified host.
- (void)setVerifiedFailover:(BOOL)failover;

// Ends this span with the result's status, then calls handler. Returns handler unchanged when this span doesn't
// record.
- (void (^_Nullable)(RadarStatus, RadarVerifiedLocationToken *_Nullable))endingTrackVerifiedHandler:
    (void (^_Nullable)(RadarStatus, RadarVerifiedLocationToken *_Nullable))handler;

// Traces the fraud SDK's payload preparation as a radar.fraud.prepare child, which starts now and ends before handler
// runs.
- (void (^)(RadarStatus, RadarPreparedFraudPayloadWrapper *_Nullable, NSError *_Nullable))tracingFraudPrepareHandler:
    (void (^)(RadarStatus, RadarPreparedFraudPayloadWrapper *_Nullable, NSError *_Nullable))handler;

@end

NS_ASSUME_NONNULL_END
