//
//  RadarDelegate.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radar.h"
#import "RadarEvent.h"
#import "RadarUser.h"

@protocol RadarDelegate <NSObject>

/**
 @abstract Tells the delegate that events were received for the user. Note that events can also be delivered server-side via webhooks.
 @param events The events received.
 @param user The user.
 */
- (void)didReceiveEvents:(NSArray<RadarEvent *> * _Nonnull)events user:(RadarUser * _Nonnull)user NS_SWIFT_NAME(didReceiveEvents(_:user:));

@optional
/**
 @abstract Tells the delegate that a request failed.
 @param status The status.
 */
- (void)didFailWithStatus:(RadarStatus)status NS_SWIFT_NAME(didFail(status:));

@end
