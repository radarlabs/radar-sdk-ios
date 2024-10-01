//
//  RadarInitializeOptions.h
//  RadarSDK
//
//  Created by Kenny Hu on 9/10/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarURLDelegate.h"
#import <Foundation/Foundation.h>


@interface RadarInitializeOptions : NSObject

@property (assign, nonatomic) BOOL autoLogNotificationConversions;
@property (assign, nonatomic) BOOL autoHandleNotificationDeepLinks;
@property (nullable, weak, nonatomic) id<RadarURLDelegate> urlDelegate;

- (NSDictionary *_Nonnull)dictionaryValue;
- (instancetype _Nonnull)initWithDict:(NSDictionary *_Nullable)dict;

@end

