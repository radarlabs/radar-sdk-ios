//
//  RadarProfiler.h
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RadarProfiler: NSObject

- (void)start:(NSString*_Nullable)tag;
- (void)end:(NSString*_Nullable)tag;
- (double)get:(NSString*_Nullable)tag;
- (NSString*_Nonnull)formatted;

@end
