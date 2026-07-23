//
//  RadarSwiftBridge.m
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RadarSwiftBridge.h"
#import "RadarReplayBuffer.h"
#import "Radar+Internal.h"
#import "RadarState.h"
#import "RadarLogger.h"
#import "RadarUtils.h"
#import "RadarDelegateHolder.h"
#import "RadarAPIClient.h"
#import "RadarNotificationHelper.h"

@implementation RadarSwiftBridge

- (void)flushReplays {
    [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (void)logOpenedAppConversion {
    [Radar logOpenedAppConversion];
}

- (NSArray<NSString *> * _Nullable)geofenceIds {
    return [RadarState geofenceIds];
}

- (NSArray<NSString *> * _Nullable)beaconIds {
    return [RadarState beaconIds];
}

- (NSString * _Nullable)placeId {
    return [RadarState placeId];
}

- (RadarTripOptions * _Nullable)getTripOptions {
    return [Radar getTripOptions];
}

- (CLLocation * _Nullable)lastLocation {
    return [RadarState lastLocation];
}

- (BOOL)isStopped {
    return [RadarState stopped];
}

- (void)logCampaignConversionWithName:(NSString *)name metadata:(NSDictionary<NSString *, id> * _Nonnull)metadata campaign:(NSString * _Nullable)campaign {
    [Radar sendLogConversionRequestWithName:name metadata:metadata campaign:campaign completionHandler:^(RadarStatus status, RadarEvent * _Nullable event) {
        NSString *message = [NSString stringWithFormat:@"Conversion name = %@: status = %@; event = %@", event.conversionName, [Radar stringForStatus:status], event];
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:message];
    }];
}

- (RadarEvent * _Nullable)createEventWithDict:(NSDictionary *)dict {
    return [[RadarEvent alloc] initWithObject:dict];
}

- (RadarUser * _Nullable)createUserWithDict:(NSDictionary *)dict {
    return [[RadarUser alloc] initWithObject:dict];
}

- (RadarGeofence * _Nullable)createGeofenceWithDict:(NSDictionary *)dict {
    return [[RadarGeofence alloc] initWithObject:dict];
}

- (BOOL)isForeground {
    return [RadarUtilsDeprecated foreground];
}

- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events user:(RadarUser *)user {
    [[RadarDelegateHolder sharedInstance] didReceiveEvents:events user:user];
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    [[RadarDelegateHolder sharedInstance] didUpdateClientLocation:location stopped:stopped source:source];
}

- (RadarUser * _Nullable)radarUser {
    return [RadarState radarUser];
}

- (void)flushReplaysRequest:(NSArray<NSDictionary *> *)replays
          completionHandler:(void (^)(RadarStatus, NSDictionary * _Nullable))completionHandler {
    [[RadarAPIClient sharedInstance] flushReplays:replays completionHandler:^(RadarStatus status, NSDictionary * _Nullable res) {
        if (completionHandler) {
            completionHandler(status, res);
        }
    }];
}

- (void)didFailWithStatus:(RadarStatus)status {
    [[RadarDelegateHolder sharedInstance] didFailWithStatus:status];
}

- (RadarBeacon * _Nonnull)createBeaconWithUuid:(NSString *)uuid major:(NSString *)major minor:(NSString *)minor rssi:(NSInteger)rssi {
    return [[RadarBeacon alloc] initWithUUID:uuid major:major minor:minor rssi:rssi];
}

- (RadarBeacon * _Nonnull)createBeaconFromRegion:(CLBeaconRegion *)region {
    return [RadarBeacon fromCLBeaconRegion:region];
}

- (void)setRssi:(NSInteger)rssi onBeacon:(RadarBeacon *)beacon {
    [beacon setRssi:rssi];
}

- (nullable UNMutableNotificationContent *)extractContentFromMetadata:(nullable NSDictionary *)metadata identifier:(nullable NSString *)identifier {
    return [RadarNotificationHelper extractContentFromMetadata:metadata identifier:identifier];
}

- (void)updateClientSideCampaignsWithPrefix:(NSString *)prefix notificationRequests:(NSArray<UNNotificationRequest *> *)requests {
    [RadarNotificationHelper updateClientSideCampaignsWithPrefix:prefix notificationRequests:requests];
}

@end
