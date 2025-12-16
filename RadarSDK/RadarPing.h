//
//  RadarPing.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

API_AVAILABLE(ios(13.0))
@interface RadarPing : NSObject
+ (RadarPing * _Nonnull)shared;
- (void)pingWithCompletionHandler:(void (^ _Nonnull)(NSDictionary<NSString *, NSNumber *> * _Nonnull))completionHandler;
@end
