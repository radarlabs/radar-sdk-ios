
#import "RadarBeaconManager.h"
#import "RadarBeaconManager+Internal.h"

#import "RadarAPIClient.h"
#import "RadarBeaconScanRequest+Internal.h"
#import "RadarCollectionAdditions.h"
#import "RadarSettings.h"
#import "RadarUtils.h"

NS_ASSUME_NONNULL_BEGIN

static double const kRadarBeaconMonitorTimeoutSecond = 10.00f;
static NSUInteger const kRadarBeaconMonitorLimit = 20;
static int const kRadarBeaconSearchRadius = 1000;
static int const kRadarBeaconSearchLimit = 20;

dispatch_source_t CreateDispatchTimer(double interval, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

NSArray<NSString *> *BeaconIdsFromRadarBeacons(NSArray<RadarBeacon *> *radarBeacons) {
    return [radarBeacons radar_mapObjectsUsingBlock:^id _Nullable(RadarBeacon *_Nonnull radarBeacon) {
        return radarBeacon._id;
    }];
};

@implementation RadarBeaconManager {
    NSMutableArray<RadarBeaconScanRequest *> *_queuedRequests;
    RadarBeaconScanRequest *_runningRequest;

    dispatch_source_t _timer;

    dispatch_queue_t _workQueue;

    // tracking
    CLLocation *_latestLocation;
    RadarLocationSource _latestLocationSource;
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
        // TODO: smarter on the timer start
        [self _startTimer];
    }
    return self;
}

- (void)dealloc {
    if (_timer) {
        [self _cancelTimer];
    }
}

#pragma mark - track Once with timer

- (void)detectOnceForLocation:(CLLocation *)location completionBlock:(RadarBeaconDetectionCompletionHandler)completionBlock {
    // TODO: make trackOnce work with tracking;
    if ([self isTracking]) {
        completionBlock(RadarStatusErrorBeacon, nil);
    }

    [[RadarAPIClient sharedInstance] searchBeaconsNear:location
                                                radius:kRadarBeaconSearchRadius
                                                 limit:kRadarBeaconSearchLimit
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons) {
                                         if (status != RadarStatusSuccess) {
                                             completionBlock(status, nil);
                                             return;
                                         }

                                         if (!beacons || beacons.count == 0) {
                                             completionBlock(status, @[]);
                                             return;
                                         }
                                         [self detectOnceForRadarBeacons:beacons completionBlock:completionBlock];
                                     }];
}

- (void)detectOnceForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons completionBlock:(RadarBeaconDetectionCompletionHandler)block {
    // TODO: make getContext work with tracking;
    if ([self isTracking]) {
        block(RadarStatusErrorBeacon, nil);
    }
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        if (radarBeacons.count == 0) {
            return block(RadarStatusSuccess, @[]);
        }

        RadarBeaconScanRequest *request = [self _scanRequestForRadarBeacons:radarBeacons shouldTrack:NO completionHandler:block];
        [self _enqueueRequest:request];
    });
}

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
    if (!_runningRequest && _queuedRequests.count == 0) {
        return;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSArray *queuedRequestsCopy = [_queuedRequests copy];
    for (RadarBeaconScanRequest *request in queuedRequestsCopy) {
        if (now >= request.expiration) {
            if (request.detectionCompletionHandler) {
                request.detectionCompletionHandler(RadarStatusErrorBeacon, nil);
            }
            [_queuedRequests removeObject:request];
        }
    }

    if (_runningRequest && now >= _runningRequest.expiration) {
        [self _didDetectBeaconsWithStatus:RadarStatusErrorBeacon nearbyBeacons:nil];
        [self _finishRunningRequest];
    }
}

#pragma mark - continuous tracking
- (BOOL)isTracking {
    return [RadarSettings beaconTracking];
}

- (void)setTracking:(BOOL)tracking {
    [RadarSettings setBeaconTracking:tracking];
}

- (void)startTracking {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        // cancel all ongoing on-time detection requests
        // TODO: need revisit
        for (RadarBeaconScanRequest *request in self->_queuedRequests) {
            if (request.detectionCompletionHandler) {
                request.detectionCompletionHandler(RadarStatusErrorBeacon, nil);
            }
        }

        [self->_queuedRequests removeAllObjects];

        if (self->_runningRequest) {
            [self _didDetectBeaconsWithStatus:RadarStatusErrorBeacon nearbyBeacons:nil];
            [self _finishRunningRequest];
        }

        [self setTracking:YES];
    });
}

- (void)stopTracking {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        [self setTracking:NO];
    });
}

- (void)updateTrackingWithLocation:(CLLocation *)location source:(RadarLocationSource)source completionHandler:(nullable RadarBeaconDetectionCompletionHandler)completionHandler {
    if (source == RadarLocationSourceMockLocation || source == RadarLocationSourceUnknown || source == RadarLocationSourceManualLocation) {
        // no op when the provided location is not the device location
        return;
    }
    weakify(self);
    [[RadarAPIClient sharedInstance] searchBeaconsNear:location
                                                radius:kRadarBeaconSearchRadius
                                                 limit:kRadarBeaconSearchLimit
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarBeacon *> *_Nullable beacons) {
                                         if (status != RadarStatusSuccess || !beacons) {
                                             return;
                                         }
                                         strongify_else_return(self);
                                         dispatch_async(self->_workQueue, ^{
                                             strongify_else_return(self);
                                             [self _didDetectBeaconsWithStatus:RadarStatusErrorBeacon nearbyBeacons:nil];
                                             [self _finishRunningRequest];
                                             RadarBeaconScanRequest *request = [self _scanRequestForRadarBeacons:beacons shouldTrack:YES completionHandler:completionHandler];
                                             [self _enqueueRequest:request];
                                         });
                                     }];
}

#pragma mark - scheduling
- (void)_enqueueRequest:(RadarBeaconScanRequest *)request {
    [_queuedRequests addObject:request];
    [self _scheduleRequest];
}

- (void)_scheduleRequest {
    if (_runningRequest) {
        return;
    }

    if (_queuedRequests.count == 0) {
        return;
    }

    RadarBeaconScanRequest *request = [_queuedRequests firstObject];
    [_queuedRequests removeObjectAtIndex:0];

    _runningRequest = request;
    [_beaconScanner startScanWithRequest:request];
}

- (void)_finishRunningRequest {
    if (_runningRequest) {
        [_beaconScanner stopScan];
        _runningRequest = nil;
        [self _scheduleRequest];
    }
}

#pragma mark - RadarBeaconScannerDelegate

- (void)didFailWithStatus:(RadarStatus)status forScanRequest:(RadarBeaconScanRequest *)request {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        [self _didDetectBeaconsWithStatus:status nearbyBeacons:nil];
        // TODO: handle error under tracking mode
        [self _finishRunningRequest];
    });
}

- (void)didDetermineStatesWithNearbyBeacons:(NSArray<RadarBeacon *> *)nearbyBeacons forScanRequest:(RadarBeaconScanRequest *)request {
    weakify(self);
    dispatch_async(_workQueue, ^{
        strongify_else_return(self);
        [self _didDetectBeaconsWithStatus:RadarStatusSuccess nearbyBeacons:nearbyBeacons];
        if (!self->_runningRequest.shouldTrack) {
            [self _finishRunningRequest];
        }
    });
}

- (void)_didDetectBeaconsWithStatus:(RadarStatus)status nearbyBeacons:(nullable NSArray<RadarBeacon *> *)nearbyBeacons {
    if (self->_runningRequest.detectionCompletionHandler) {
        // Make sure that the completionBlock is called at most once for each scan request
        self->_runningRequest.detectionCompletionHandler(status, nearbyBeacons);
        self->_runningRequest.detectionCompletionHandler = nil;
    }
}

- (void)didUpdateNearbyBeacons:(NSArray<RadarBeacon *> *)nearbyBeacons forScanRequest:(RadarBeaconScanRequest *)request {
    let nearbyBeaconIds = BeaconIdsFromRadarBeacons(nearbyBeacons);
    // TODO: need discussions
    [[RadarAPIClient sharedInstance] trackWithLocation:_latestLocation
                                               stopped:NO
                                            foreground:NO
                                                source:_latestLocationSource
                                              replayed:NO
                                         nearbyBeacons:nearbyBeaconIds
                                     completionHandler:^(RadarStatus status, NSDictionary *_Nullable res, NSArray<RadarEvent *> *_Nullable events, RadarUser *_Nullable user){
                                         // NO OP
                                     }];
}

#pragma mark-- private helpers
- (RadarBeaconScanRequest *)_scanRequestForRadarBeacons:(NSArray<RadarBeacon *> *)radarBeacons
                                            shouldTrack:(BOOL)shouldTrack
                                      completionHandler:(RadarBeaconDetectionCompletionHandler _Nullable)completionHandler;
{
    NSArray *beaconsToMonitor = [radarBeacons subarrayWithRange:NSMakeRange(0, MIN(kRadarBeaconMonitorLimit, radarBeacons.count))];
    NSTimeInterval expiration = [[NSDate date] timeIntervalSince1970] + kRadarBeaconMonitorTimeoutSecond;
    if (shouldTrack) {
        expiration = [[NSDate distantFuture] timeIntervalSince1970];
    }
    RadarBeaconScanRequest *request = [[RadarBeaconScanRequest alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]
                                                                              expiration:expiration
                                                                             shouldTrack:shouldTrack
                                                                                 beacons:beaconsToMonitor
                                                                       completionHandler:completionHandler];
    return request;
}

@end

NS_ASSUME_NONNULL_END
