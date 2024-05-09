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
@property (nonatomic, assign) BOOL backgroundPopupAvailable;
@property (nonatomic, assign) BOOL foregroundPopupAvailable;
@property (nonatomic, assign) BOOL userRejectedBackgroundPermissions;

- (NSDictionary *_Nonnull)dictionaryValue;


@end


