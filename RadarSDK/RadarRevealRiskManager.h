//
//  RadarRevealRiskManager.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/13/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarRevealRisk.h"

@interface RadarRevealRiskManager : NSObject
+ (RadarRevealRiskManager * _Nonnull)shared;
- (void)revealRiskWithFraudPayload:(NSString * _Nonnull)fraudPayload useSecondaryVerifiedHost:(BOOL)useSecondaryVerifiedHost completionHandler:(void (^ _Nonnull)(RadarRevealRisk * _Nullable))completionHandler;
@end
