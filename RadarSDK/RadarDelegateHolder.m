//
//  RadarDelegateHolder.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarDelegateHolder.h"

#import "RadarLogger.h"

@implementation RadarDelegateHolder

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events user:(RadarUser *)user {
    if (!events || !events.count) {
        return;
    }

    if (self.delegate) {
        [self.delegate didReceiveEvents:events user:user];
    }

    for (RadarEvent *event in events) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                           message:[NSString stringWithFormat:@"📍 Radar event received | type = %@; link = https://radar.io/dashboard/events/%@",
                                                                              [RadarEvent stringForType:event.type], event._id]];
    }
}

- (void)didUpdateLocation:(CLLocation *)location user:(RadarUser *)user {
    if (!location || !user) {
        return;
    }

    if (self.delegate) {
        [self.delegate didUpdateLocation:location user:user];
    }

    [[RadarLogger sharedInstance]
        logWithLevel:RadarLogLevelInfo
             message:[NSString stringWithFormat:@"📍 Radar location updated | coordinates = (%f, %f); accuracy = %f; link = https://radar.io/dashboard/users/%@",
                                                user.location.coordinate.latitude, user.location.coordinate.longitude, user.location.horizontalAccuracy, user._id]];
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    if (!location) {
        return;
    }

    if (self.delegate) {
        [self.delegate didUpdateClientLocation:location stopped:stopped source:source];
    }
}

- (void)didFailWithStatus:(RadarStatus)status {
    if (self.delegate) {
        [self.delegate didFailWithStatus:status];
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"📍 Radar error received | status = %@", [Radar stringForStatus:status]]];
}

- (void)didLogMessage:(NSString *)message {
    if (self.delegate) {
        [self.delegate didLogMessage:message];
    }
}

@end
