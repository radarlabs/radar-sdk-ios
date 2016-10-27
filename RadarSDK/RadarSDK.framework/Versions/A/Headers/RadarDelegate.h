//
//  RadarDelegate.h
//  RadarSDK
//
//  Created by Nicholas Patrick on 10/3/16.
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarEvent.h"

@protocol RadarDelegate <NSObject>

/**
 @abstract Tells the delegate that events were received. Note that events can also be delivered server-side via webhooks.
 @param events The events received.
 */
- (void)didReceiveEvents:(NSArray<RadarEvent *> *)events;

@end
