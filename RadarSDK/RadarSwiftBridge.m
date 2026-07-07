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

@implementation RadarSwiftBridge

- (void)flushReplays {
    [[RadarReplayBuffer sharedInstance] flushReplaysWithCompletionHandler:nil completionHandler:nil];
}

- (void)logOpenedAppConversion {
    [Radar logOpenedAppConversion];
}

- (void)invokeWithTarget:(NSObject * _Nonnull)target selector:(SEL _Nonnull)selector args:(NSArray * _Nonnull)args {
    if ([target respondsToSelector:selector]) {
        NSMethodSignature *signature = [target methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = target;
        invocation.selector = selector;

        // Note: Objective-C method arguments start at index 2 (0 = self, 1 = _cmd).
        for (int i = 0; i < args.count; ++i) {
            id arg = args[i];
            [invocation setArgument:&arg atIndex:i + 2];
        }

        [invocation invoke];
    } else {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                           message:[NSString stringWithFormat:@"Cannot invoke %@ on target", NSStringFromSelector(selector)]];
    }
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

@end
