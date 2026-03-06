//
//  RadarSwiftBridge.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarEvent+Internal.h"
#import "RadarGeofence+Internal.h"
#import "RadarLogBuffer.h"
#import "RadarTrackingOptions.h"
#import "RadarState.h"
#import "RadarBeacon+Internal.h"
#import "RadarPlace+Internal.h"
#import "RadarTripOptions.h"
#import <CoreLocation/CoreLocation.h>

@protocol RadarSwiftBridgeProtocol
- (void)writeToLogBufferWithLevel:(RadarLogLevel)level type:(RadarLogType)type message:(NSString * _Nonnull)message forcePersist:(BOOL)forcePersist;
- (void)setLogBufferPersistantLog:(BOOL)value;
- (void)flushReplays;
- (void)logOpenedAppConversion;

- (CLCircularRegion * _Nullable)syncedRegion;
- (NSArray<NSString *> * _Nullable)geofenceIds;
- (NSArray<NSString *> * _Nullable)beaconIds;
- (NSString * _Nullable)placeId;
- (NSArray<RadarGeofence *> * _Nullable)geofencesFromObject:(id _Nonnull)object;
- (NSArray<RadarPlace *> * _Nullable)placesFromObject:(id _Nonnull)object;
- (NSArray<RadarBeacon *> * _Nullable)beaconsFromObject:(id _Nonnull)object;
- (NSArray<RadarGeofence *> * _Nullable)syncedGeofences;
- (NSArray<RadarBeacon *> * _Nullable)syncedBeacons;
- (NSArray<RadarPlace *> * _Nullable)syncedPlaces;
- (CLLocation * _Nullable)lastLocation;
- (void)fetchSyncRegionWithLatitude:(double)latitude longitude:(double)longitude completionHandler:(void (^ _Nonnull)(RadarStatus status, NSDictionary * _Nullable res))completionHandler;
- (void)setSyncedGeofences: (NSArray<RadarGeofence *> *_Nullable)geofences;
- (void)setSyncedBeacons:(NSArray<RadarBeacon *> * _Nullable)beacons;
- (void)setSyncedPlaces:(NSArray<RadarPlace *> * _Nullable)places;
- (void)setSyncedRegion:(CLCircularRegion * _Nullable)region;
- (NSArray<NSString *> * _Nonnull)lastSyncedGeofenceIds;
- (void)setLastSyncedGeofenceIds:(NSArray<NSString *> * _Nullable)ids;
- (NSArray<NSString *> * _Nonnull)lastSyncedPlaceIds;
- (void)setLastSyncedPlaceIds:(NSArray<NSString *> * _Nullable)ids;
- (NSArray<NSString *> * _Nonnull)lastSyncedBeaconIds;
- (void)setLastSyncedBeaconIds:(NSArray<NSString *> * _Nullable)ids;
- (NSDictionary<NSString *, NSDate *> * _Nonnull)geofenceEntryTimestamps;
- (void)setGeofenceEntryTimestamps:(NSDictionary<NSString *, NSDate *> * _Nullable)timestamps;
- (NSArray<NSString *> * _Nonnull)dwellEventsFired;
- (void)setDwellEventsFired:(NSArray<NSString *> * _Nullable)ids;
- (BOOL)isStopped;
- (RadarTripOptions * _Nullable)getTripOptions;
@end

@interface RadarSwiftBridge: NSObject<RadarSwiftBridgeProtocol>
@end

@interface RadarSwift : NSObject
@property (nonatomic, class, strong) id <RadarSwiftBridgeProtocol> _Nullable bridge;

+ (id <RadarSwiftBridgeProtocol> _Nullable)bridge;
+ (void)setBridge:(id <RadarSwiftBridgeProtocol> _Nullable)value;
- (nonnull instancetype)init;
@end
