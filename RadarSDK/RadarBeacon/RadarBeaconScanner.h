
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarBeacon.h"
#import "RadarBeaconScanRequest.h"
#import "RadarPermissionsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarBeaconScannerDelegate

/// Called when the initial states (inside or outside) of all beacons are determined.
/// @param nearbyBeacons The detected nearby beacons.
/// @param request The scan request.
- (void)didDetermineStatesWithNearbyBeacons:(NSArray<RadarBeacon *> *)nearbyBeacons forScanRequest:(RadarBeaconScanRequest *)request;

/// Called when there is any update on nearby beacons AFTER initial states have determined.
/// @param nearbyBeacons The latest nearby beacons.
/// @param request The scan request
- (void)didUpdateNearbyBeacons:(NSArray<RadarBeacon *> *)nearbyBeacons forScanRequest:(RadarBeaconScanRequest *)request;

/// Called when the scan fails.
/// @param status The error status.
/// @param request The scan request.
- (void)didFailWithStatus:(RadarStatus)status forScanRequest:(RadarBeaconScanRequest *)request;

@end

@interface RadarBeaconScanner : NSObject

- (instancetype)initWithDelegate:(__weak id<RadarBeaconScannerDelegate>)delegate
                 locationManager:(CLLocationManager *)locationManager
               permissionsHelper:(RadarPermissionsHelper *)permissionsHelper;

- (void)startMonitoringWithRequest:(RadarBeaconScanRequest *)request;

- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
