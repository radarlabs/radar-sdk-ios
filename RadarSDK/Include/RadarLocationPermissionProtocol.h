//
//  RadarLocationPermissionProtocol.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/2/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarLocationPermissionProtocol<NSObject>

- (void)requestBackgroundPermission;


@end

NS_ASSUME_NONNULL_END

