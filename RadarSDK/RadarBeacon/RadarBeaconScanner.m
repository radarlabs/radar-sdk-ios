
#import "RadarBeaconScanner.h"
#import "RadarBeacon+CLBeacon.h"
#import "RadarBeaconManager.h"
#import "RadarCollectionAdditions.h"
#import "RadarLogger.h"
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

    BOOL _hasDetectedAllRegions;
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

- (void)startScanWithRequest:(RadarBeaconScanRequest *)request {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify_else_return(self);
        if (self->_runningRequest) {
            // TODO: this should not happen
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:@"Beacon Scanner is busy."];
            [self->_delegate didFailWithStatus:RadarStatusErrorBeacon forScanRequest:request];
            return;
        }

        RadarStatus permissionStatus = [self _permissionStatus];
        if (permissionStatus != RadarStatusSuccess) {
            [self->_delegate didFailWithStatus:permissionStatus forScanRequest:request];
            return;
        }

        NSArray<CLBeaconRegion *> *regions = [request.beacons radar_mapObjectsUsingBlock:^id _Nullable(RadarBeacon *_Nonnull beacon) {
            return [beacon toCLBeaconRegion];
        }];

        NSMutableDictionary<NSString *, CLBeaconRegion *> *allRegions = [NSMutableDictionary dictionary];
        for (CLBeaconRegion *region in regions) {
            allRegions[region.identifier] = region;
        }
        self->_allRegions = [allRegions copy];

        self->_detectedRegionIds = [NSMutableSet set];
        self->_enteredRegionIds = [NSMutableSet set];
        self->_hasDetectedAllRegions = NO;
        self->_runningRequest = request;

        for (CLBeaconRegion *region in regions) {
            [self->_locationManager stopRangingBeaconsInRegion:region];
            [self->_locationManager startRangingBeaconsInRegion:region];
            NSString *message = [NSString stringWithFormat:@"Start scan for beacon region  | id: %@, uuid: %@, major: %@, minor: %@", region.identifier,
                                                           region.proximityUUID.UUIDString, region.major, region.minor];
            [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:message];
        }
    });
}

- (void)stopScan {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify_else_return(self);
        for (CLBeaconRegion *region in [self->_allRegions allValues]) {
            [self->_locationManager stopRangingBeaconsInRegion:region];
        }
        self->_runningRequest = nil;
        self->_allRegions = nil;
        self->_detectedRegionIds = nil;
        self->_enteredRegionIds = nil;
        self->_hasDetectedAllRegions = NO;
    });
}

#pragma mark - location manager range
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(nonnull NSArray<CLBeacon *> *)beacons inRegion:(nonnull CLBeaconRegion *)region {
    if (![self _isRegionOfInterest:region]) {
        return;
    }

    [_detectedRegionIds addObject:region.identifier];
    if (beacons.count > 0) {
        [_enteredRegionIds addObject:region.identifier];
    } else if ([_enteredRegionIds containsObject:region.identifier]) {
        [_enteredRegionIds removeObject:region.identifier];
    }

    if (_detectedRegionIds.count == _allRegions.count) {
        NSMutableArray<RadarBeacon *> *nearbyRadarBeacons = [NSMutableArray array];
        for (RadarBeacon *radarBeacon in _runningRequest.beacons) {
            // RadarBeacon._id is the region.identifier
            if ([_enteredRegionIds containsObject:radarBeacon._id]) {
                [nearbyRadarBeacons addObject:radarBeacon];
            }
        }

        if (!_hasDetectedAllRegions) {
            // detected all beacons for the first time
            [_delegate didDetermineStatesWithNearbyBeacons:nearbyRadarBeacons forScanRequest:_runningRequest];
            _hasDetectedAllRegions = YES;
        } else {
            [_delegate didUpdateNearbyBeacons:nearbyRadarBeacons forScanRequest:_runningRequest];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(nonnull CLBeaconRegion *)region withError:(nonnull NSError *)error {
    NSString *message = [NSString stringWithFormat:@"Failed scan for beacon region %@ | Error %@", region.identifier, error];
    [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:message];
    [_delegate didFailWithStatus:RadarStatusErrorBeacon forScanRequest:_runningRequest];
}

#pragma mark - private helpers

- (BOOL)_isRegionOfInterest:(CLRegion *)region {
    return [region isKindOfClass:[CLBeaconRegion class]] && [_allRegions objectForKey:region.identifier];
}

- (RadarStatus)_permissionStatus {
    CLAuthorizationStatus authorizationStatus = [_permissionsHelper locationAuthorizationStatus];
    if (!(authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        return RadarStatusErrorPermissions;
    }

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
