//
//  RadarPermissionsHelper.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarPermissionsHelper : NSObject

- (CLAuthorizationStatus)locationAuthorizationStatus;

@end

NS_ASSUME_NONNULL_END
