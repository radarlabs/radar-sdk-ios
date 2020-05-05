
#import "RadarBeaconScanner.h"
#import "RadarBeacon+CLBeacon.h"
#import "RadarBeaconManager.h"
#import "RadarCollectionAdditions.h"
#import "RadarUtils.h"

@interface RadarBeaconScanner ()<CLLocationManagerDelegate>

@end

@implementation RadarBeaconScanner {
    CLLocationManager *_locationManager;
    __weak id<RadarBeaconScannerDelegate> _delegate;
    RadarPermissionsHelper *_permissionsHelper;

    RadarBeaconScanRequest *_runningRequest;
    NSDictionary<NSString *, CLBeaconRegion *> *_allRegions;
    NSMutableSet<NSString *> *_detectedRegionIds;
    NSMutableSet<NSString *> *_enteredRegionIds;

    BOOL _isMonitoring;
}

- (instancetype)initWithDelegate:(id<RadarBeaconScannerDelegate>)delegate
                 locationManager:(nonnull CLLocationManager *)locationManager
               permissionsHelper:(nonnull RadarPermissionsHelper *)permissionsHelper {
    if (self = [super init]) {
        _locationManager = locationManager;
        _locationManager.allowsBackgroundLocationUpdates = [RadarUtils allowsBackgroundLocationUpdates];
        _locationManager.delegate = self;

        _delegate = delegate;
        _permissionsHelper = permissionsHelper;
    }
    return self;
}

- (void)startMonitoringWithRequest:(RadarBeaconScanRequest *)request {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify_else_return(self);
        RadarStatus permissionStatus = [self _permissionStatus];
        if (permissionStatus != RadarStatusSuccess) {
            [self->_delegate didFinishMonitoring:request status:permissionStatus nearbyBeacons:nil];
        }

        if (self->_isMonitoring) {
            // TODO: we should probably have another status for scanner busy error.
            // but that status needs to be private (so not part of RadarStatus)
            [self->_delegate didFinishMonitoring:request status:RadarStatusErrorBeacon nearbyBeacons:nil];
        }

        self->_isMonitoring = YES;

        self->_runningRequest = request;
        NSArray<CLBeaconRegion *> *regions = [request.beacons radar_mapObjectsUsingBlock:^id _Nullable(RadarBeacon *_Nonnull beacon) {
            return [beacon toCLBeaconRegion];
        }];
        self->_allRegions = [regions
            radar_mapToDictionaryUsingKeyBlock:^id _Nullable(CLBeaconRegion *_Nonnull region) {
                return region.identifier;
            }
            valueBlock:^id _Nullable(CLBeaconRegion *_Nonnull region) {
                return region;
            }];

        self->_detectedRegionIds = [NSMutableSet set];
        self->_enteredRegionIds = [NSMutableSet set];

        for (NSString *regionId in self->_allRegions) {
            CLBeaconRegion *region = self->_allRegions[regionId];
            [self->_locationManager startMonitoringForRegion:region];
        }
    });
}

- (void)stopMonitoring {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify_else_return(self);
        self->_runningRequest = nil;
        self->_allRegions = nil;
        self->_detectedRegionIds = nil;
        self->_enteredRegionIds = nil;
        self->_isMonitoring = NO;
    });
}

#pragma mark - monitoring delegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if (![self _isRegionOfInterest:region]) {
        return;
    }
    [self _handleInsideRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if (![self _isRegionOfInterest:region]) {
        return;
    }
    [self _handleOutsideRegion:(CLBeaconRegion *)region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(nonnull CLRegion *)region {
    if (![self _isRegionOfInterest:region]) {
        return;
    }

    BOOL isInside = (state == CLRegionStateInside);

    if (isInside) {
        [self _handleInsideRegion:(CLBeaconRegion *)region];
    } else {
        [self _handleOutsideRegion:(CLBeaconRegion *)region];
    }
}

- (void)_handleInsideRegion:(CLBeaconRegion *)region {
    [_enteredRegionIds addObject:region.identifier];
    [self _handleBeaconDiscovery:region];
}

- (void)_handleOutsideRegion:(CLBeaconRegion *)region {
    if ([_enteredRegionIds containsObject:region.identifier]) {
        [_enteredRegionIds removeObject:region.identifier];
    }
    [self _handleBeaconDiscovery:region];
}

- (void)_handleBeaconDiscovery:(CLBeaconRegion *)region {
    [_detectedRegionIds addObject:region.identifier];
    if (_detectedRegionIds.count == _allRegions.count) {
        // detected all beacons
        NSMutableArray<RadarBeacon *> *nearbyBeacons = [NSMutableArray array];
        for (RadarBeacon *beacon in _runningRequest.beacons) {
            if ([_detectedRegionIds containsObject:beacon._id]) {
                [nearbyBeacons addObject:beacon];
            }
        }
        [_delegate didFinishMonitoring:_runningRequest status:RadarStatusSuccess nearbyBeacons:nearbyBeacons];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error {
    [_delegate didFinishMonitoring:_runningRequest status:RadarStatusErrorBeacon nearbyBeacons:nil];
}

#pragma mark - private helpers

- (BOOL)_isRegionOfInterest:(CLRegion *)region {
    return [region isKindOfClass:[CLBeaconRegion class]] && [_allRegions objectForKey:region.identifier];
}

- (RadarStatus)_permissionStatus {
    switch (_permissionsHelper.bluetoothState) {
    case CBManagerStatePoweredOff:
        return RadarStatusErrorBluetoothPoweredOff;
    case CBManagerStatePoweredOn:
        return RadarStatusSuccess;
    case CBManagerStateResetting:
        return RadarStatusErrorBluetoothResetting;
    case CBManagerStateUnauthorized:
        return RadarStatusErrorBluetoothPermission;
    case CBManagerStateUnsupported:
        return RadarStatusErrorBluetoothUnsupported;
    case CBManagerStateUnknown:
        return RadarStatusErrorUnknown;
    }
}

@end
