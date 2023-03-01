//
//  RadarDelegateHolder.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Radar.h"
#import "RadarDelegate.h"
#import "RadarMeta.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarDelegateHolder : NSObject<RadarDelegate>

@property (nullable, weak, nonatomic) id<RadarDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)didFailWithStatus:(RadarStatus)status meta:(RadarMeta *_Nullable)meta;

@end

NS_ASSUME_NONNULL_END
