//
//  RadarRevealRiskManager.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarRevealRiskToken.h"

@interface RadarRevealRiskManager : NSObject
+ (RadarRevealRiskManager * _Nonnull)shared;
- (void)setRevealRiskId:(NSString * _Nullable)revealRiskId;
- (NSString * _Nullable)getRevealRiskId;
- (void)revealRiskWithUseSecondaryVerifiedHost:(BOOL)useSecondaryVerifiedHost completionHandler:(void (^ _Nonnull)(RadarStatus, RadarRevealRiskToken * _Nullable))completionHandler;
@end
