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

- (NSDictionary *)dictionaryValue;
- (instancetype)initWithDict:(NSDictionary *)dict;

@end

