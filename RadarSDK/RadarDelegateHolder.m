//
//  RadarDelegateHolder.m
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarDelegateHolder.h"
#import "RadarLogger.h"
#import "RadarUtils.h"
#if __has_include(<RadarSDK/RadarSDK-Swift.h>)
#import <RadarSDK/RadarSDK-Swift.h>
#elif __has_include("RadarSDK-Swift.h")
#import "RadarSDK-Swift.h"
#endif

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

    if (self.delegate && [self.delegate respondsToSelector:@selector(didReceiveEvents:user:)]) {
        [self.delegate didReceiveEvents:events user:user];
    }
    
    [RadarEventNotifications showNotificationsFor:events];

    for (RadarEvent *event in events) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo
                                           message:[NSString stringWithFormat:@"📍 Radar event received | type = %@; replayed = %d; link = https://radar.com/dashboard/events/%@",
                                                                              [RadarEvent stringForType:event.type], event.replayed, event._id]];
    }
}

- (void)didUpdateLocation:(CLLocation *)location user:(RadarUser *)user {
    if (!location || !user) {
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateLocation:user:)]) {
        [self.delegate didUpdateLocation:location user:user];
    }

    [[RadarLogger sharedInstance]
        logWithLevel:RadarLogLevelInfo
             message:[NSString stringWithFormat:@"📍 Radar location updated | coordinates = (%f, %f); accuracy = %f; link = https://radar.com/dashboard/users/%@",
                                                user.location.coordinate.latitude, user.location.coordinate.longitude, user.location.horizontalAccuracy, user._id]];
}

- (void)didUpdateClientLocation:(CLLocation *)location stopped:(BOOL)stopped source:(RadarLocationSource)source {
    if (!location) {
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(didUpdateClientLocation:stopped:source:)]) {
        [self.delegate didUpdateClientLocation:location stopped:stopped source:source];
    }
}

- (void)didFailWithStatus:(RadarStatus)status {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFailWithStatus:)]) {
        [self.delegate didFailWithStatus:status];
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError type:RadarLogTypeSDKError message:[NSString stringWithFormat:@"📍 Radar error received | status = %@", [Radar stringForStatus:status]]];
}

- (void)didLogMessage:(NSString *)message {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didLogMessage:)]) {
        [self.delegate didLogMessage:message];
    }
}

- (void)didUpdateToken:(RadarVerifiedLocationToken *)token {
    if (self.verifiedDelegate && [self.verifiedDelegate respondsToSelector:@selector(didUpdateToken:)]) {
        [self.verifiedDelegate didUpdateToken:token];
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"📍 Radar token updated | passed = %d; expiresAt = %@; expiresIn = %f; token = %@", token.passed, token.expiresAt, token.expiresIn, token.token]];
}

- (void)didChangeIP {
    if (self.verifiedDelegate && [self.verifiedDelegate respondsToSelector:@selector(didChangeIP)]) {
        [self.verifiedDelegate didChangeIP];
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:@"📍 Radar IP changed"];
}

- (void)didChangeSharing:(BOOL)sharing {
    if (self.verifiedDelegate && [self.verifiedDelegate respondsToSelector:@selector(didChangeSharing:)]) {
        [self.verifiedDelegate didChangeSharing:sharing];
    }

    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelInfo message:[NSString stringWithFormat:@"📍 Radar sharing changed | sharing = %d", sharing]];
}

@end
