//
//  Header.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/16/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "RadarConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarOfflineManager : NSObject

+ (void)contextualizeLocation:(CLLocation *)location completionHandler:(void (^)(RadarConfig *))completionHandler;

@end

NS_ASSUME_NONNULL_END
