//
//  RadarBeaconManager.m
//  Library
//
//  Created by Ping Xia on 4/28/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeaconManager.h"
#import "RadarBeaconManager+Internal.h"

#import "RadarBeaconScanRequest.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

static double const kRadarBeaconMonitorTimeoutSecond = 10.00f;

dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

@implementation RadarBeaconManager {
    NSMutableArray<RadarBeaconScanRequest *> *_queuedRequests;
    RadarBeaconScanRequest *_runningRequest;

    NSMutableDictionary<NSString *, RadarBeaconMonitorCompletionHandler> *_completionHandlers;

    BOOL _isMonitoring;

    dispatch_source_t _timer;

    dispatch_queue_t _workQueue;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [[RadarBeaconManager alloc] init];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [[RadarBeaconManager alloc] init];
            });
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _beaconScanner = [[RadarBeaconScanner alloc] initWithDelegate:self locationManager:[CLLocationManager new] permissionsHelper:[RadarPermissionsHelper new]];

        _workQueue = dispatch_queue_create_with_target("com.radar.beaconManager", DISPATCH_QUEUE_SERIAL, DISPATCH_TARGET_QUEUE_DEFAULT);
        _queuedRequests = [NSMutableArray array];
        _completionHandlers = [NSMutableDictionary dictionary];
        [self _startTimer];
    }
    return self;
}

- (void)dealloc {
    if (_timer) {
        [self _cancelTimer];
    }
}

- (void)monitorOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconMonitorCompletionHandler)block {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        if (radarBeacons.count == 0) {
            return block(RadarStatusSuccess, @[]);
        }
        RadarBeaconScanRequest *request = [[RadarBeaconScanRequest alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                            createdTimestamp:[[NSDate date] timeIntervalSince1970]
                                                                                     beacons:radarBeacons];
        [self->_queuedRequests addObject:request];
        self->_completionHandlers[request.identifier] = block;

        [self _scheduleRequest];
    });
}

#pragma mark - timer for cancellation
- (void)_startTimer {
    if (!_timer) {
        weakify(self);
        _timer = CreateDispatchTimer(kRadarBeaconMonitorTimeoutSecond / 2.0, _workQueue, ^{
            strongify_else_return(self);
            [self _cancelTimedOutRequests];
        });
    }
}

- (void)_cancelTimer {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

- (void)_cancelTimedOutRequests {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    for (RadarBeaconScanRequest *request in _queuedRequests) {
        if (now - request.createdTimestamp >= kRadarBeaconMonitorTimeoutSecond) {
            [self _cancelRequest:request];
        }
    }

    if (_runningRequest && now - _runningRequest.createdTimestamp >= kRadarBeaconMonitorTimeoutSecond) {
        [self _cancelRequest:_runningRequest];
    }
}

#pragma mark - scheduling
- (void)_scheduleRequest {
    if (_isMonitoring) {
        return;
    }

    if (_queuedRequests.count == 0) {
        return;
    }

    RadarBeaconScanRequest *request = [_queuedRequests firstObject];
    [_queuedRequests removeObjectAtIndex:0];

    _runningRequest = request;
    _isMonitoring = YES;
    [_beaconScanner startMonitoringWithRequest:request];
}

- (void)_cancelRequest:(RadarBeaconScanRequest *)request {
    if ([_queuedRequests containsObject:request]) {
        [_queuedRequests removeObject:request];
        RadarBeaconMonitorCompletionHandler completion = _completionHandlers[request.identifier];
        if (completion) {
            completion(RadarStatusErrorBeacon, nil);
            [_completionHandlers removeObjectForKey:request.identifier];
        }
        return;
    }

    if ([request.identifier isEqualToString:_runningRequest.identifier]) {
        RadarBeaconMonitorCompletionHandler completion = _completionHandlers[request.identifier];
        if (completion) {
            completion(RadarStatusErrorBeacon, nil);
            [_completionHandlers removeObjectForKey:request.identifier];
        }
        [_beaconScanner stopMonitoring];
    }
}

- (void)_didFinishMonitoring {
    [_beaconScanner stopMonitoring];
    _isMonitoring = NO;
    _runningRequest = nil;
    [self _scheduleRequest];
}

#pragma mark - RadarBeaconScannerDelegate

- (void)didFailStartMonitoring {
    // No op for now.
}

- (void)didFinishMonitoring:(RadarBeaconScanRequest *)request status:(RadarStatus)status nearbyBeacons:(NSArray<RadarBeacon *> *_Nullable)nearbyBeacons {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        RadarBeaconMonitorCompletionHandler completion = self->_completionHandlers[request.identifier];
        if (completion) {
            completion(status, nearbyBeacons);
            [self->_completionHandlers removeObjectForKey:request.identifier];
        }
        [self _didFinishMonitoring];
    });
}

@end

NS_ASSUME_NONNULL_END
