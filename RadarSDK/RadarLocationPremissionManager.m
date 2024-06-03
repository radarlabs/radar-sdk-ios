//
//  RadarLocationPremissionsManager.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLocationPermissionManager.h"
#import "RadarLocationPermissionStatus+Internal.h"
#import "RadarDelegateHolder.h"

@interface RadarLocationPermissionManager ()

@property (assign, nonatomic) BOOL danglingBackgroundPermissionRequest;
@property (assign, nonatomic) BOOL inBackgroundLocationPopUp;

@end

@implementation RadarLocationPermissionManager

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
        RadarLocationPermissionStatus *status = [RadarLocationPermissionStatus getRadarLocationPermissionStatus];
        if (status) {
            self.status = status;
            // we should not start in the popup state
            self.status.inForegroundPopup = NO;
        } else{
            if (@available(iOS 14.0, *)) {
                self.status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                            backgroundPopupAvailable:YES
                                                                   inForegroundPopup:NO
                                                   userRejectedBackgroundPermission:NO];
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
    // TODO: sync the user's state with the new permission status here
    return self;
}

- (void)updateStatus:(RadarLocationPermissionStatus *)status {
    self.status = status;
    /*
    [RadarLocationPermissionStatus radarLocationPermissionStatus:status];
    if (@available(iOS 14.0, *)) {
        [[RadarDelegateHolder sharedInstance] didUpdateLocationPermissionStatus:self.status];
        // TODO: sync the user's state with the new permission status here
    }
    */
}

- (void)openAppSettings {
    NSURL *appSettingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:appSettingsURL]) {
        [[UIApplication sharedApplication] openURL:appSettingsURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"Successfully opened settings");
                // TODO: sync the user's location permission action with the their permission status here
            } else {
                NSLog(@"Failed to open settings");
                // TODO: sync the user's location permission action with the their permission status here
            }
        }];
    }
}

- (void)requestBackgroundLocationPermission {
    if (self.status.locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {

        self.danglingBackgroundPermissionRequest = YES;

        [self.locationManager requestAlwaysAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                   backgroundPopupAvailable:NO
                                                                                          inForegroundPopup:self.status.inForegroundPopup
                                                                          userRejectedBackgroundPermission: self.status.userRejectedBackgroundPermission];
            [self updateStatus:status];
            // TODO: sync the user's location permission action with the their permission status here
        }

        // We set a flag that request has been made and start a timer. If we resign active we unset the timer.
        // When the timer fires and the flag has not been unset, we assume that app never resigned active.
        // Usually this means that the user has previously rejected the background permission.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.danglingBackgroundPermissionRequest) {
                if (@available(iOS 14.0, *)) {
                    RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                            backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                                    inForegroundPopup:self.status.inForegroundPopup
                                                                                    userRejectedBackgroundPermission:YES];
                    [self updateStatus:status];
                }
            }
            self.danglingBackgroundPermissionRequest = NO;
        });
    }
}


- (void)requestForegroundLocationPermission {
    if (self.status.locationManagerStatus == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                   backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                          inForegroundPopup:YES
                                                                          userRejectedBackgroundPermission: self.status.userRejectedBackgroundPermission];
            [self updateStatus:status];
        }
        // TODO: sync the user's location permission action with the their permission status here
    }    
}

- (void)applicationDidBecomeActive {
    // we need to handle the case of double updates, we only want to update the status if and only if we are coming back from a popup and the status has changed.
    if (self.inBackgroundLocationPopUp) {

        if (@available(iOS 14.0, *)) {
            CLAuthorizationStatus status = self.locationManager.authorizationStatus;
            if (status == self.status.locationManagerStatus) {
                // if the status did not changed, we update the status here, otherwise we will update it in the delegate method
                RadarLocationPermissionStatus *newStatus = [[RadarLocationPermissionStatus alloc] initWithStatus:status
                                                                                          backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                                 inForegroundPopup:self.status.inForegroundPopup
                                                                                 userRejectedBackgroundPermission: YES];
                [self updateStatus:newStatus];
            }
        }
    }

    self.inBackgroundLocationPopUp = NO;
}


- (void)applicationWillResignActive {
    if (self.danglingBackgroundPermissionRequest) {
        self.inBackgroundLocationPopUp = YES;
    }
    self.danglingBackgroundPermissionRequest = NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    RadarLocationPermissionStatus *newStatus = [[RadarLocationPermissionStatus alloc] initWithStatus:status
                                                                              backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                     // any change in status will always result in the in foreground popup closing
                                                                                     inForegroundPopup:NO
                                                                     userRejectedBackgroundPermission: 
                                                                     self.status.userRejectedBackgroundPermission || (status == kCLAuthorizationStatusDenied)];
    [self updateStatus:newStatus];
}

- (RadarLocationPermissionStatus *)getLocationPermissionStatus {
    if (@available(iOS 14.0, *)) {
        return self.status;
    }
    return nil;
}

@end
