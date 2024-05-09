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
#import "RadarDelegateHolder.h"

@implementation RadarLocationPermissionsManager{
    BOOL danglingBackgroundPermissionsRequest;
    BOOL inBackgroundLocationPopUp;
}

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
        RadarLocationPermissionsStatus *status = [RadarLocationPermissionsStatus retrieve];
        if (status) {
            self.status = status;
        } else{
            if (@available(iOS 14.0, *)) {
                self.status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                      backgroundPopupAvailable:YES
                                                      foregroundPopupAvailable:YES
                                                      userRejectedBackgroundPermissions:NO];
            } else {
                // Fallback on earlier versions
            }
        }
       
        // while we do not know if the request prompt has been sent before, we know that if a pop-up appears the app will resign active.
        // a simple implementation to "update" such a status will be to listen to the UIApplicationWillResignActiveNotification. 
        //For example, an update can be sent unless its been interupted by the resign active.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];        
        
    }
    return self;
}

- (void)updateStatus:(RadarLocationPermissionsStatus *)status {
    self.status = status;
    [RadarLocationPermissionsStatus store:status];
    [self sendDelegateUpdate];
}

- (void)sendDelegateUpdate {
   [[RadarDelegateHolder sharedInstance] didUpdateLocationPermissionsStatus:self.status];
}


- (void)requestLocationPermissions:(BOOL)background {
    if (background && self.status.locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {

        danglingBackgroundPermissionsRequest = YES;

        [self.locationManager requestAlwaysAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                             backgroundPopupAvailable:NO
                                                                             foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                          userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
            [self updateStatus:status];
        } else {
            // Fallback on earlier versions
        }

        // Start a timer
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->danglingBackgroundPermissionsRequest) {
                NSLog(@"pop-up did not show");
                if (@available(iOS 14.0, *)) {
                    RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                     backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                     foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                                  userRejectedBackgroundPermissions:YES];
                    [self updateStatus:status];
                } else {
                    // Fallback on earlier versions
                }
            }
            self->danglingBackgroundPermissionsRequest = NO;
        });


        // Right here under normal circumstances we will expect to see the app resign active. 
        // If it does not happen then the user has previously rejected background permissions.
        // If the app does not resign active in 2 seconds, we should mark a flag.


        // We set a flag that request has been made and start a timer. If we resign active we unset the timer.
        // when the timer fires and the flag has not been unset, we assume that app never resigned active.

        // we set another flag to determine the results of the popup.
        // when the requested flag has been set and the app resigns active, we know that the resgin active is due to the popup.
        // We can then set the in-location-pop-up flag to true.
        // When the app comes to the foreground, we can check the in-location-pop-up flag and determine if the user has rejected the popup.

    }
    if (!background) {
        [self.locationManager requestWhenInUseAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                             backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                             foregroundPopupAvailable:NO
                                                                          userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
            [self updateStatus:status];
        } else {
            // Fallback on earlier versions
        }
    }
}

- (void)applicationDidBecomeActive {
    if (inBackgroundLocationPopUp) {
        NSLog(@"User has rejected background location permissions");
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                             backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                             foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                          userRejectedBackgroundPermissions:YES];
            [self updateStatus:status];
        } else {
            // Fallback on earlier versions
        }
    }
    inBackgroundLocationPopUp = NO;
}


- (void)applicationWillResignActive {
    if (danglingBackgroundPermissionsRequest) {
        inBackgroundLocationPopUp = YES;
    }
    danglingBackgroundPermissionsRequest = NO;
}




- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {

    // something we might need to handle, if we ever encounter a situation where the user previously denied the location permissions
    // we should not bother trying to show the pop-up, its almost akin to the user previously requuested the permissions.

    RadarLocationPermissionsStatus *newStatus = [[RadarLocationPermissionsStatus alloc] initWithStatus:status
                                                                 backgroundPopupAvailable:self.status.backgroundPopupAvailable && !(status == kCLAuthorizationStatusDenied)
                                                                 foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                 userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
    [self updateStatus:newStatus];
}

- (RadarLocationPermissionsStatus *)getLocationPermissionsStatus {
    return self.status;
}


@end



