//
//  RadarDelegateHolder.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarDelegate.h"
#import "RadarVerifiedDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarDelegateHolder : NSObject<RadarDelegate, RadarVerifiedDelegate>

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;
@property (nullable, weak, nonatomic) id<RadarVerifiedDelegate> verifiedDelegate;

+ (instancetype)sharedInstance;
- (void)didFailWithStatus:(RadarStatus)status;

@end

NS_ASSUME_NONNULL_END
