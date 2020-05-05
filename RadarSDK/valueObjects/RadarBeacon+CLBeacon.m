
#import "RadarBeacon+CLBeacon.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RadarBeacon (CLBeacon)

- (CLBeaconRegion *_Nullable)toCLBeaconRegion {
    NSUUID *uuid = [self _NSUUID];
    if (!uuid) {
        return nil;
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *majorNumber = [formatter numberFromString:self.major];
    NSNumber *minorNumber = [formatter numberFromString:self.minor];
    return [[CLBeaconRegion alloc] initWithProximityUUID:uuid major:[majorNumber unsignedShortValue] minor:[minorNumber unsignedShortValue] identifier:self._id];
}

- (NSUUID *_Nullable)_NSUUID {
    if (![self.uuid containsString:@"-"] && self.uuid.length == 32) {
        @try {
            NSString *firstComponent = [self.uuid substringWithRange:NSMakeRange(0, 8)];
            NSString *secondComponent = [self.uuid substringWithRange:NSMakeRange(8, 4)];
            NSString *thirdComponent = [self.uuid substringWithRange:NSMakeRange(12, 4)];
            NSString *fourthComponent = [self.uuid substringWithRange:NSMakeRange(16, 4)];
            NSString *lastComponent = [self.uuid substringWithRange:NSMakeRange(20, 12)];
            NSString *formatedUUIDString = [NSString stringWithFormat:@"%@-%@-%@-%@-%@", firstComponent, secondComponent, thirdComponent, fourthComponent, lastComponent];
            return [[NSUUID alloc] initWithUUIDString:formatedUUIDString];
        } @catch (NSException *exception) {
            return nil;
        }
    } else {
        return [[NSUUID alloc] initWithUUIDString:self.uuid];
    }
}

@end

NS_ASSUME_NONNULL_END
