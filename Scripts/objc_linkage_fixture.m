#import <RadarSDK/RadarSDK.h>

int main(void) {
    @autoreleasepool {
        RadarTripOptions *options = [[RadarTripOptions alloc]
            initWithExternalId:@"fence-3044"
            destinationGeofenceTag:nil
            destinationGeofenceExternalId:nil];
        return options == nil;
    }
}
