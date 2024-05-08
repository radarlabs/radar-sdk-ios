//
//  RadarLocationPremissionsManager.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLocationPermissionsManager.h"
#import "RadarLocationPermissionsStatus+Internal.h"

@implementation RadarLocationPermissionsManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        // we need to get this from storage
        if (@available(iOS 14.0, *)) {
            self.status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                  requestedBackgroundPermissions:NO
                                                  requestedForegroundPermissions:NO];
        } else {
            // Fallback on earlier versions
        }
        // while we do not know if the request prompt has been sent before, we know that if a pop-up appears the app will resign active.
        // a simple implementation to "update" such a status will be to listen to the UIApplicationWillResignActiveNotification. 
        //For example, an update can be sent unless its been interupted by the resign active.
        // [[NSNotificationCenter defaultCenter] addObserver:[self sharedInstance]
        //                                          selector:@selector(applicationWillEnterForeground)
        //                                              name:UIApplicationWillResignActiveNotification
        //                                            object:nil];
    }
    return self;
}


- (void)requestLocationPermissions:(BOOL)background {
    if (background) {
        [self.locationManager requestAlwaysAuthorization];
    } else {
        [self.locationManager requestWhenInUseAuthorization];
    }
}



- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // Handle the change in authorization status

}


@end



