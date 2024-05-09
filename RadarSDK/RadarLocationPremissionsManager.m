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
                // just a dummy value, this component will not communicate with the rest of the SDK if the version is below 14.0
                self.status = [[RadarLocationPermissionsStatus alloc] initWithStatus: kCLAuthorizationStatusAuthorizedAlways
                                                      backgroundPopupAvailable:NO
                                                      foregroundPopupAvailable:NO
                                                      userRejectedBackgroundPermissions:NO];
            }
        }
       
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
    if (@available(iOS 14.0, *)) {
        [[RadarDelegateHolder sharedInstance] didUpdateLocationPermissionsStatus:self.status];
    }
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
        }

        // We set a flag that request has been made and start a timer. If we resign active we unset the timer.
        // When the timer fires and the flag has not been unset, we assume that app never resigned active.
        // Usually this means that the user has previously rejected the background permissions.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self->danglingBackgroundPermissionsRequest) {
                NSLog(@"pop-up did not show");
                if (@available(iOS 14.0, *)) {
                    RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                     backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                     foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                                  userRejectedBackgroundPermissions:YES];
                    [self updateStatus:status];
                }
            }
            self->danglingBackgroundPermissionsRequest = NO;
        });
    }
    if (!background) {
        [self.locationManager requestWhenInUseAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                             backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                             foregroundPopupAvailable:NO
                                                                          userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
            [self updateStatus:status];
        }
    }
}

- (void)applicationDidBecomeActive {
    if (inBackgroundLocationPopUp) {
        // we assume that the app is becoming active due to the popup closing.
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionsStatus *status = [[RadarLocationPermissionsStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                             backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                             foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                          userRejectedBackgroundPermissions:YES];
            [self updateStatus:status];
        }
    }
    inBackgroundLocationPopUp = NO;
}


- (void)applicationWillResignActive {
    if (danglingBackgroundPermissionsRequest) {
        // we set a flag to determine if the app resigns active due to the popup.
        inBackgroundLocationPopUp = YES;
    }
    danglingBackgroundPermissionsRequest = NO;
}




- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    RadarLocationPermissionsStatus *newStatus = [[RadarLocationPermissionsStatus alloc] initWithStatus:status
                                                                 backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                 foregroundPopupAvailable:self.status.foregroundPopupAvailable
                                                                 userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions  || (status == kCLAuthorizationStatusDenied)];
    [self updateStatus:newStatus];
}

- (RadarLocationPermissionsStatus *)getLocationPermissionsStatus {
    if (@available(iOS 14.0, *)) {
        return self.status;
    }
    return nil;
}


@end



