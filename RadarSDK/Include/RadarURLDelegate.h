//
//  RadarURLDelegate.h
//  RadarSDK
//
//  Created by Kenny Hu on 10/1/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A delegate tpo handle notification opens with embedded URLs. For more information, see https://radar.com/documentation/notifications

 @see https://radar.com/documentation/notifications
 */
@protocol RadarURLDelegate<NSObject>

/**
 Tells the delegate that URL was received.

 @param url The URL received.
 */
- (BOOL)didHandleURL:(NSURL *)url NS_SWIFT_NAME(didHandleURL(_:));

@end

NS_ASSUME_NONNULL_END
