//
//  RadarLocationPermissionsStatus.h
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface RadarLocationPermissionsStatus : NSObject

@property (nonatomic, assign) CLAuthorizationStatus locationManagerStatus;
@property (nonatomic, assign) BOOL requestedBackgroundPermissions;
@property (nonatomic, assign) BOOL requestedForegroundPermissions;

- (NSDictionary *_Nonnull)dictionaryValue;


@end
