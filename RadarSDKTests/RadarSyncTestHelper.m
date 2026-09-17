//
//  RadarSyncTestHelper.m
//  RadarSDK
//
//  Created by Alan Charles on 4/9/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarSyncTestHelper.h"
#import "RadarState.h"

@implementation RadarSyncTestHelper
+ (void)setStopped:(BOOL)stopped { [RadarState setStopped:stopped]; }
+ (void)setRadarUser:(RadarUser *)user { [RadarState setRadarUser:user]; }
@end

@implementation RadarTrackTestBridge
+ (void)trackWithPayload:(NSString *_Nullable)payload
                verified:(BOOL)verified
               secondary:(BOOL)secondary
              completion:(RadarTrackAPICompletionHandler)completion {
    [[RadarAPIClient sharedInstance] trackWithLocation:[[CLLocation alloc] initWithLatitude:40.0 longitude:-73.0]
                                             stopped:NO
                                          foreground:YES
                                              source:RadarLocationSourceForegroundLocation
                                            replayed:NO
                                             beacons:nil
                                      indoorLocation:nil
                                            verified:verified
                                        fraudPayload:payload
                                 expectedCountryCode:nil
                                   expectedStateCode:nil
                                              reason:nil
                                       transactionId:nil
                                        revealRiskId:nil
                            useSecondaryVerifiedHost:secondary
                                   completionHandler:completion];
}
@end
