
#import "RadarBeaconManager.h"
#import "RadarBeaconScanner.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconManager ()<RadarBeaconScannerDelegate>
// expose for testing

@property (nonatomic, strong, nonnull) RadarBeaconScanner *beaconScanner;

@end

NS_ASSUME_NONNULL_END
