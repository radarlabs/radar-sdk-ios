
#import "RadarBeacon.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeacon (CLBeacon)

// create a CLBeaconRegion for the RadarBeacon. The region's identifier is the RadarBeacon._id
- (CLBeaconRegion *)toCLBeaconRegion;

@end

NS_ASSUME_NONNULL_END
