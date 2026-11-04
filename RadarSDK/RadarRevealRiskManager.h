//
//  RadarRevealRiskManager.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"

@class RadarRevealRiskToken;

@interface RadarRevealRiskManager : NSObject
+ (RadarRevealRiskManager * _Nonnull)shared;
@property (nonatomic, copy, nullable) NSString *revealRiskId;
- (void)revealRiskWithUseSecondaryVerifiedHost:(BOOL)useSecondaryVerifiedHost completionHandler:(void (^ _Nonnull)(RadarStatus, RadarRevealRiskToken * _Nullable))completionHandler;
@end
