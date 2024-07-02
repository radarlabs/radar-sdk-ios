//
//  RadarInitializeOptions.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarInitializeOptions.h"
#import <Foundation/Foundation.h>

@implementation RadarInitializeOptions

NSString *const kUserId = @"userId";
NSString *const kMetadata = @"metadata";

+ (RadarInitializeOptions *_Nonnull)fromDictionary:(NSDictionary *_Nullable)dictionary {
    RadarInitializeOptions* options = [[RadarInitializeOptions alloc] init];
    
    if (!dictionary) {
        return options;
    }
    
    options.userId = dictionary[kUserId];
    options.metadata = dictionary[kMetadata];
    
    return options;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kUserId] = self.userId;
    dict[kMetadata] = self.metadata;
    return dict;
}

@end
