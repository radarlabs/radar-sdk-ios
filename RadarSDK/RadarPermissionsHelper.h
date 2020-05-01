//
//  RadarPermissionsHelper.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadarPermissionsHelper : NSObject

- (CLAuthorizationStatus)locationAuthorizationStatus;
- (CBManagerState)bluetoothState;

@end

NS_ASSUME_NONNULL_END
