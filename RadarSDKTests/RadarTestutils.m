//
//  RadarTestUtils.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTestUtils.h"

@implementation RadarTestUtils

+ (NSDictionary *)jsonDictionaryFromResource:(NSString *)resource {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:resource ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *deserializationError = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
    NSDictionary *jsonDict = (NSDictionary *)jsonObj;
    return jsonDict;
}

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
                                    expectedStateCode:(NSString * _Nullable)expectedStateCode{
    NSMutableDictionary *params = [NSMutableDictionary new];
    BOOL anonymous = [RadarSettings anonymousTrackingEnabled];
    params[@"anonymous"] = @(anonymous);
    if (anonymous) {
        params[@"deviceId"] = @"anonymous";
        params[@"geofenceIds"] = [RadarState geofenceIds];
        params[@"placeId"] = [RadarState placeId];
        params[@"regionIds"] = [RadarState regionIds];
        params[@"beaconIds"] = [RadarState beaconIds];
    } else {
        params[@"id"] = [RadarSettings _id];
        params[@"installId"] = [RadarSettings installId];
        params[@"userId"] = [RadarSettings userId];
        params[@"deviceId"] = [RadarUtilsDeprecated deviceId];
        params[@"description"] = [RadarSettings __description];
        params[@"metadata"] = [RadarSettings metadata];
        NSString *sessionId = [RadarSettings sessionId];
        if (sessionId) {
            params[@"sessionId"] = sessionId;
        }
    }
    params[@"latitude"] = @(location.coordinate.latitude);
    params[@"longitude"] = @(location.coordinate.longitude);
    CLLocationAccuracy accuracy = location.horizontalAccuracy;
    if (accuracy <= 0) {
        accuracy = 1;
    }
    params[@"accuracy"] = @(accuracy);
    params[@"altitude"] = @(location.altitude);
    params[@"verticalAccuracy"] = @(location.verticalAccuracy);
    params[@"speed"] = @(location.speed);
    params[@"speedAccuracy"] = @(location.speedAccuracy);
    params[@"course"] = @(location.course);
    if (@available(iOS 13.4, *)) {
        params[@"courseAccuracy"] = @(location.courseAccuracy);
    }
    if (location.floor) {
        params[@"floorLevel"] = @(location.floor.level);
    }
    long nowMs = (long)([NSDate date].timeIntervalSince1970 * 1000);
    if (!foreground) {
        long timeInMs = (long)(location.timestamp.timeIntervalSince1970 * 1000);
        params[@"updatedAtMsDiff"] = @(nowMs - timeInMs);
    }
    params[@"foreground"] = @(foreground);
    params[@"stopped"] = @(stopped);
    params[@"replayed"] = @(replayed);
    params[@"deviceType"] = [RadarUtils deviceType];
    params[@"deviceMake"] = [RadarUtils deviceMake];
    params[@"sdkVersion"] = [RadarUtils sdkVersion];
    params[@"deviceModel"] = [RadarUtils deviceModel];
    params[@"deviceOS"] = [RadarUtilsDeprecated deviceOS];
    params[@"country"] = [RadarUtils country];
    params[@"timeZoneOffset"] = [RadarUtils timeZoneOffset];
    params[@"source"] = [Radar stringForLocationSource:source];
    if ([RadarSettings xPlatform]) {
        params[@"xPlatformType"] = [RadarSettings xPlatformSDKType];
        params[@"xPlatformSDKVersion"] = [RadarSettings xPlatformSDKVersion];
    } else {
        params[@"xPlatformType"] = @"Native";
    }
    NSMutableArray<NSString *> *fraudFailureReasons = [NSMutableArray new];
    if (@available(iOS 15.0, *)) {
        CLLocationSourceInformation *sourceInformation = location.sourceInformation;
        if (sourceInformation) {
            if (sourceInformation.isSimulatedBySoftware) {
                params[@"mocked"] = @(YES);
                [fraudFailureReasons addObject:@"fraud_mocked_from_mock_provider"];
            }
            if (sourceInformation.isProducedByAccessory) {
                [fraudFailureReasons addObject:@"fraud_mocked_produced_by_accessory"];
            }
        }
    }
    
    RadarTripOptions *tripOptions = Radar.getTripOptions;
    
    if (tripOptions) {
        NSMutableDictionary *tripParams = [NSMutableDictionary new];
        tripParams[@"version"] = @("2");
        [tripParams setValue:tripOptions.externalId forKey:@"externalId"];
        [tripParams setValue:tripOptions.metadata forKey:@"metadata"];
        [tripParams setValue:tripOptions.destinationGeofenceTag forKey:@"destinationGeofenceTag"];
        [tripParams setValue:tripOptions.destinationGeofenceExternalId forKey:@"destinationGeofenceExternalId"];
        [tripParams setValue:[Radar stringForMode:tripOptions.mode] forKey:@"mode"];
        params[@"tripOptions"] = tripParams;
    }
    
    RadarTrackingOptions *options = [Radar getTrackingOptions];
    if (options.syncGeofences) {
        params[@"nearbyGeofences"] = @(YES);
    }
    if (beacons) {
        params[@"beacons"] = [RadarBeacon arrayForBeacons:beacons];
    }
    NSString *locationAuthorization = [RadarUtils locationAuthorization];
    if (locationAuthorization) {
        params[@"locationAuthorization"] = locationAuthorization;
    }
    NSString *locationAccuracyAuthorization = [RadarUtils locationAccuracyAuthorization];
    if (locationAccuracyAuthorization) {
        params[@"locationAccuracyAuthorization"] = locationAccuracyAuthorization;
    }
    params[@"notificationAuthorization"] = [RadarState notificationPermissionGranted] ? @"true" : @"false";
    
    params[@"trackingOptions"] = [options dictionaryValue];
    
    BOOL usingRemoteTrackingOptions = RadarSettings.tracking && RadarSettings.remoteTrackingOptions;
    params[@"usingRemoteTrackingOptions"] = @(usingRemoteTrackingOptions);
    
    params[@"verified"] = @(verified);
    if (verified) {
        params[@"attestationString"] = attestationString;
        params[@"keyId"] = keyId;
        params[@"attestationError"] = attestationError;
        params[@"encrypted"] = @(encrypted);
        BOOL jailbroken = [[RadarVerificationManager sharedInstance] isJailbroken];
        params[@"compromised"] = @(jailbroken);
        if (jailbroken) {
            [fraudFailureReasons addObject:@"fraud_compromised_jailbroken"];
        }
        if (expectedCountryCode) {
            params[@"expectedCountryCode"] = expectedCountryCode;
        }
        if (expectedStateCode) {
            params[@"expectedStateCode"] = expectedStateCode;
        }
    }
    params[@"appId"] = [[NSBundle mainBundle] bundleIdentifier];
    RadarSdkConfiguration *sdkConfiguration = [RadarSettings sdkConfiguration];

    params[@"fraudFailureReasons"] = fraudFailureReasons;
    
    // added after API call fail
    params[@"replayed"] = @(YES);
    params[@"updatedAtMs"] = @(nowMs);
    
    return params;
}

@end
