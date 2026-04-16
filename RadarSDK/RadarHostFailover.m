//
//  RadarHostFailover.m
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarHostFailover.h"
#import "RadarLogger.h"

static const NSTimeInterval kBackoffInterval = 60.0;

@interface RadarHostFailover ()

@property (strong, nonatomic) dispatch_queue_t stateQueue;
@property (strong, nonatomic) NSArray<NSString *> *hosts;
@property (assign, nonatomic) NSUInteger activeHostIndex;
@property (strong, nonatomic, nullable) NSDate *lastFailureTime;
@property (assign, nonatomic) BOOL isProbingPrimary;

@end

@implementation RadarHostFailover

- (instancetype)initWithHosts:(NSArray<NSString *> *)hosts {
    self = [super init];
    if (self) {
        NSAssert(hosts.count > 0, @"RadarHostFailover requires at least one host");
        _stateQueue = dispatch_queue_create("io.radar.hostfailover", DISPATCH_QUEUE_SERIAL);
        _hosts = [hosts copy];
        _activeHostIndex = 0;
        _lastFailureTime = nil;
        _isProbingPrimary = NO;
    }
    return self;
}

- (NSString *)currentHost {
    __block NSString *host;
    dispatch_sync(self.stateQueue, ^{
        if (self.activeHostIndex == 0) {
            // Normal mode: use primary
            host = self.hosts[0];
            self.isProbingPrimary = NO;
        } else {
            // Failover mode: check if backoff period has elapsed
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.lastFailureTime];
            if (elapsed >= kBackoffInterval) {
                // Time to probe the primary
                host = self.hosts[0];
                self.isProbingPrimary = YES;
                [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                                  message:[NSString stringWithFormat:@"Host failover: probing primary host %@", host]];
            } else {
                // Still in backoff: use current fallback
                host = self.hosts[self.activeHostIndex];
                self.isProbingPrimary = NO;
            }
        }
    });
    return host;
}

- (void)reportSuccess {
    dispatch_sync(self.stateQueue, ^{
        if (self.isProbingPrimary) {
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                              message:@"Host failover: primary host recovered, switching back"];
            self.activeHostIndex = 0;
            self.lastFailureTime = nil;
        }
        self.isProbingPrimary = NO;
    });
}

- (BOOL)reportFailure {
    __block BOOL hasAlternate = NO;
    dispatch_sync(self.stateQueue, ^{
        if (self.isProbingPrimary) {
            // Probe failed: stay on current fallback, update failure time
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                              message:@"Host failover: primary probe failed, staying on fallback"];
            self.lastFailureTime = [NSDate date];
            self.isProbingPrimary = NO;
            hasAlternate = YES;
        } else if (self.activeHostIndex + 1 < self.hosts.count) {
            // Advance to next host
            self.activeHostIndex = self.activeHostIndex + 1;
            self.lastFailureTime = [NSDate date];
            self.isProbingPrimary = NO;
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                              message:[NSString stringWithFormat:@"Host failover: switching to fallback host %@", self.hosts[self.activeHostIndex]]];
            hasAlternate = YES;
        }
        // else: already on last host, no more alternates
    });
    return hasAlternate;
}

@end
