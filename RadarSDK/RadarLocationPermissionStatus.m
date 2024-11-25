//
//  RadarLocationPermissionsStatus.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarLocationPermissionStatus.h"
#import "RadarLocationPermissionStatus+Internal.h"

@implementation RadarLocationPermissionStatus

+ (void)radarLocationPermissionStatus:(RadarLocationPermissionStatus *)status {
    NSDictionary *dict = [status dictionaryValue];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"radarLocationPermissionStatus"];
}

+ (RadarLocationPermissionStatus *)getRadarLocationPermissionStatus {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"radarLocationPermissionStatus"];
    if (dict) {
        return [[RadarLocationPermissionStatus alloc] initWithDictionary:dict];
    }
    return nil;
}

- (instancetype _Nullable)initWithAccuracy:(RadarLocationPermissionAccuracy)accuracy
                        permissionGranted:(RadarLocationPermissionLevel)permissionGranted
                         requestAvailable:(RadarLocationPermissionLevel)requestAvailable {
    self = [super init];
    if (self) {
        _accuracy = accuracy;
        _permissionGranted = permissionGranted;
        _requestAvailable = requestAvailable;
    }
    return self;
}

- (NSString *)radarLocationPermissionAccuracyToString:(RadarLocationPermissionAccuracy)accuracy {
    NSString *accuracyString;
    
    switch (accuracy) {
        case RadarPermissionAccuracyFull:
            accuracyString = @"Full";
            break;
        case RadarPermissionAccuracyApproximate:
            accuracyString = @"Approximate";
            break;
        default:
            accuracyString = @"Unknown";
    }
    return accuracyString;
}

-  (RadarLocationPermissionAccuracy)radarLocationPermissionAccuracyFromString:(NSString *)accuracyString {
    RadarLocationPermissionAccuracy accuracy;
    
    if ([accuracyString isEqualToString:@"Full"]) {
        accuracy = RadarPermissionAccuracyFull;
    } else if ([accuracyString isEqualToString:@"Approximate"]) {
        accuracy = RadarPermissionAccuracyApproximate;
    } else {
        accuracy = RadarPermissionAccuracyUnknown;
    }
    return accuracy;
}

+ (RadarLocationPermissionAccuracy)radarLocationPermissionAccuracyFromCLLocationAccuracy:(CLAccuracyAuthorization)accuracy {
    RadarLocationPermissionAccuracy radarAccuracy = RadarPermissionAccuracyUnknown;
    
    if (accuracy == CLAccuracyAuthorizationReducedAccuracy) {
        radarAccuracy = RadarPermissionAccuracyApproximate;
    } 
    if (accuracy == CLAccuracyAuthorizationFullAccuracy) {
        radarAccuracy = RadarPermissionAccuracyFull;
    }
    return radarAccuracy;
}

- (NSString *)radarLocationPermissionLevelToString:(RadarLocationPermissionLevel)level {
    NSString *levelString;
    
    switch (level) {
        case RadarPermissionLevelForeground:
            levelString = @"Foreground";
            break;
        case RadarPermissionLevelBackground:
            levelString = @"BackgroundLocation";
            break;
        case RadarPermissionLevelNone:
            levelString = @"None";
            break;
        default:
            levelString = @"Unknown";
    }
    return levelString;
}

-  (RadarLocationPermissionLevel)radarLocationPermissionLevelFromString:(NSString *)levelString {
    RadarLocationPermissionLevel level;
    
    if ([levelString isEqualToString:@"Foreground"]) {
        level = RadarPermissionLevelForeground;
    } else if ([levelString isEqualToString:@"BackgroundLocation"]) {
        level = RadarPermissionLevelBackground;
    } else if ([levelString isEqualToString:@"None"]) {
        level = RadarPermissionLevelNone;
    } else {
        level = RadarPermissionLevelUnknown;
    }
    return level;
}

+ (RadarLocationPermissionLevel)radarLocationPermissionLevelFromCLLocationAuthorizationStatus:(CLAuthorizationStatus)status {
    RadarLocationPermissionLevel level;
    
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        level = RadarPermissionLevelForeground;
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        level = RadarPermissionLevelBackground;
    } else if (status == kCLAuthorizationStatusDenied) {
        level = RadarPermissionLevelNone;
    } else {
        level = RadarPermissionLevelUnknown;
    }
    return level;
}

- (NSDictionary *)dictionaryValue {
    return @{
        @"accuracy": [self radarLocationPermissionAccuracyToString:self.accuracy],
        @"permissionGranted": [self radarLocationPermissionLevelToString:self.permissionGranted],
        @"requestAvailable": [self radarLocationPermissionLevelToString:self.requestAvailable]
    };
}

- (instancetype _Nullable)initWithDictionary:(NSDictionary *)dictionary {
    return [self initWithAccuracy:[self radarLocationPermissionAccuracyFromString:dictionary[@"accuracy"]]
                permissionGranted:[self radarLocationPermissionLevelFromString:dictionary[@"permissionGranted"]]
                 requestAvailable:[self radarLocationPermissionLevelFromString:dictionary[@"requestAvailable"]]];
}

@end
