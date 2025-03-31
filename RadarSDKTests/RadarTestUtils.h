//
//  RadarTestUtils.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CLLocation+Radar.h"
#import "RadarLocationManager.h"
#import "RadarSettings.h"
#import "RadarState.h"
#import "RadarUtils.h"
#import "RadarTripOptions.h"
#import "RadarVerificationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarTestUtils : NSObject

+ (NSDictionary *)jsonDictionaryFromResource:(NSString *)resource;

/**
 Construct a track param dict which can be used to test replays from paramters of the track call.
 uses the stored values from `RadarSettings`, `RadarUtils`, and `RadarState`
 */
+ (NSMutableDictionary *)createTrackParamWithLocation:(CLLocation *_Nonnull)location
                                              stopped:(BOOL)stopped
                                           foreground:(BOOL)foreground
                                               source:(RadarLocationSource)source
                                             replayed:(BOOL)replayed
                                              beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                                             verified:(BOOL)verified
                                    attestationString:(NSString *_Nullable)attestationString
                                                keyId:(NSString *_Nullable)keyId
                                     attestationError:(NSString *_Nullable)attestationError
                                            encrypted:(BOOL)encrypted
                                  expectedCountryCode:(NSString * _Nullable)expectedCountryCode
                                    expectedStateCode:(NSString * _Nullable)expectedStateCode;

@end

NS_ASSUME_NONNULL_END
