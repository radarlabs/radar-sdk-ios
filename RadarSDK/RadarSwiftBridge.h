//
//  RadarSwiftBridge.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent.h"
#import "RadarGeofence.h"
#import "RadarTrackingOptions.h"
#import "RadarState.h"
#import "RadarBeacon.h"
#import "RadarPlace.h"
#import "RadarSegment.h"
#import <CoreLocation/CoreLocation.h>
#import "Radar.h"

@class RadarConfig;
@class RadarTripOptions;
@class RadarTraceSpan;

@protocol RadarSwiftBridgeProtocol
- (void)flushReplays;
- (void)flushReplaysRequest:(NSArray<NSDictionary *> * _Nonnull)replays
                 parentSpan:(RadarTraceSpan * _Nullable)parentSpan
          completionHandler:(void (^_Nullable)(RadarStatus status, NSDictionary * _Nullable res))completionHandler;
- (void)stopIndoorTracking;
- (void)updateIndoorTrackingWithGeofences:(NSArray<RadarGeofence *> * _Nullable)geofences;
- (void)updateTracking;
- (void)updateTrackingFromInitialize;
- (void)logOpenedAppConversion;

- (NSArray<NSString *> * _Nullable)geofenceIds;
- (NSArray<NSString *> * _Nullable)beaconIds;
- (NSString * _Nullable)placeId;
- (CLLocation * _Nullable)lastLocation;
- (BOOL)isStopped;
- (void)setStopped:(BOOL)stopped;
- (void)setLastLocation:(CLLocation * _Nullable)location;
- (CLLocation * _Nullable)lastMovedLocation;
- (void)setLastMovedLocation:(CLLocation * _Nullable)location;
- (NSDate * _Nullable)lastMovedAt;
- (void)setLastMovedAt:(NSDate * _Nonnull)date;
- (CLLocation * _Nullable)lastFailedStoppedLocation;
- (void)setLastFailedStoppedLocation:(CLLocation * _Nullable)location;
- (NSDate * _Nullable)lastSentAt;
- (void)updateLastSentAt;
- (BOOL)canExit;
- (RadarEvent * _Nullable)createEventWithDict:(NSDictionary * _Nonnull)dict;
- (RadarUser * _Nullable)createUserWithDict:(NSDictionary * _Nonnull)dict;
- (RadarGeofence * _Nullable)createGeofenceWithDict:(NSDictionary * _Nonnull)dict;
- (RadarPlace * _Nullable)createPlaceWithDict:(NSDictionary * _Nonnull)dict;
- (BOOL)isForeground;
- (NSString * _Nonnull)motionAuthorizationString;
- (RadarTripOptions * _Nullable)getTripOptions;
- (RadarUser * _Nullable)radarUser;
- (void)didReceiveEvents:(NSArray<RadarEvent *> * _Nonnull)events user:(RadarUser * _Nonnull)user;
- (void)didUpdateClientLocation:(CLLocation * _Nonnull)location stopped:(BOOL)stopped source:(RadarLocationSource)source;
- (void)handleLocation:(CLLocation * _Nonnull)location source:(RadarLocationSource)source;
- (void)handleLocation:(CLLocation * _Nonnull)location
                source:(RadarLocationSource)source
               beacons:(NSArray<RadarBeacon *> * _Nullable)beacons;
- (void)updateTracking;
- (void)didFailWithStatus:(RadarStatus)status;
- (void)trackWithLocation:(CLLocation * _Nonnull)location
                  stopped:(BOOL)stopped
                   source:(RadarLocationSource)source
                 replayed:(BOOL)replayed
                  beacons:(NSArray<RadarBeacon *> * _Nullable)beacons
           indoorLocation:(CLLocation * _Nullable)indoorLocation
                traceSpan:(RadarTraceSpan * _Nullable)traceSpan
        completionHandler:(void (^_Nonnull)(RadarStatus status,
                                            NSArray<RadarEvent *> * _Nullable events,
                                            RadarUser * _Nullable user,
                                            NSArray<RadarGeofence *> * _Nullable nearbyGeofences,
                                            RadarConfig * _Nullable config))completionHandler;
- (void)searchBeaconsNear:(CLLocation * _Nonnull)location
                   radius:(int)radius
                    limit:(int)limit
                traceSpan:(RadarTraceSpan * _Nullable)traceSpan
        completionHandler:(void (^_Nonnull)(RadarStatus status,
                                            NSArray<RadarBeacon *> * _Nullable beacons,
                                            NSArray<NSString *> * _Nullable beaconUUIDs))completionHandler;
- (RadarBeacon * _Nonnull)createBeaconWithUuid:(NSString * _Nonnull)uuid major:(NSString * _Nonnull)major minor:(NSString * _Nonnull)minor rssi:(NSInteger)rssi;
- (RadarBeacon * _Nonnull)createBeaconFromRegion:(CLBeaconRegion * _Nonnull)region;
- (void)setRssi:(NSInteger)rssi onBeacon:(RadarBeacon * _Nonnull)beacon;
- (void)autocompleteQuery:(NSString *_Nonnull)query
                     near:(CLLocation *_Nullable)near
                   layers:(NSArray<NSString *> *_Nullable)layers
                    limit:(int)limit
                  country:(NSString *_Nullable)country
                 mailable:(BOOL)mailable
             sessionToken:(NSString *_Nonnull)sessionToken
        completionHandler:(void (^_Nonnull)(RadarStatus status, NSArray<RadarAddress *> *_Nullable addresses))completionHandler;
@end

// Builds Objective-C models whose parsers are internal. Installed when the framework loads, so
// Swift model parsing doesn't depend on `Radar.initialize` the way `RadarSwift.bridge` does.
@protocol RadarModelFactoryProtocol
- (RadarGeofence * _Nullable)createGeofenceWithDict:(NSDictionary * _Nonnull)dict;
- (RadarPlace * _Nullable)createPlaceWithDict:(NSDictionary * _Nonnull)dict;
- (RadarBeacon * _Nullable)createBeaconWithDict:(NSDictionary * _Nonnull)dict;
- (RadarSegment * _Nullable)createSegmentWithDict:(NSDictionary * _Nonnull)dict;
@end

@interface RadarSwiftBridge: NSObject<RadarSwiftBridgeProtocol, RadarModelFactoryProtocol>
@end

@interface RadarSwift : NSObject
@property (nonatomic, class, strong) id <RadarSwiftBridgeProtocol> _Nullable bridge;

+ (id <RadarSwiftBridgeProtocol> _Nullable)bridge;
+ (void)setBridge:(id <RadarSwiftBridgeProtocol> _Nullable)value;
@property (nonatomic, class, strong) id <RadarModelFactoryProtocol> _Nullable modelFactory;
- (nonnull instancetype)init;
@end
