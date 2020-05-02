
#import "RadarBeacon.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeacon (CLBeacon)

- (CLBeaconRegion *)toCLBeaconRegion;

@end

NS_ASSUME_NONNULL_END
