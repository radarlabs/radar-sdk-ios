
#import "RadarBeacon+CLBeacon.h"

@implementation RadarBeacon (CLBeacon)

- (CLBeaconRegion *)toCLBeaconRegion {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:self.uuid];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *majorNumber = [formatter numberFromString:self.major];
    NSNumber *minorNumber = [formatter numberFromString:self.minor];
    return [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[majorNumber unsignedShortValue] minor:[minorNumber unsignedShortValue] identifier:self._id];
}

@end
