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

@property (assign, nonatomic) BOOL danglingBackgroundPermissionsRequest;
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
                                                   userRejectedBackgroundPermissions:NO];
            } else {
                // just a dummy value, this component will not communicate with the rest of the SDK if the version is below 14.0
                self.status = [[RadarLocationPermissionStatus alloc] initWithStatus: kCLAuthorizationStatusAuthorizedAlways
                                                            backgroundPopupAvailable:NO
                                                                   inForegroundPopup:NO
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
    // TODO: sync the user's state with the new permissions status here
    return self;
}

- (void)updateStatus:(RadarLocationPermissionStatus *)status {
    self.status = status;
    [RadarLocationPermissionStatus radarLocationPermissionStatus:status];
    if (@available(iOS 14.0, *)) {
        [[RadarDelegateHolder sharedInstance] didUpdateLocationPermissionStatus:self.status];
        // TODO: sync the user's state with the new permissions status here
    }
}

// do we want to auto open the settings, is that too heavy handed? prob not as its kinda jaring from a UX prespective, we should prompt the users first
- (void)openAppSettings {
    NSURL *appSettingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:appSettingsURL]) {
        [[UIApplication sharedApplication] openURL:appSettingsURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"Successfully opened settings");
                // TODO: sync the user's location permissions action with the their permissions status here
            } else {
                NSLog(@"Failed to open settings");
                // TODO: sync the user's location permissions action with the their permissions status here
            }
        }];
    }
}

- (void)requestBackgroundLocationPermission {
    if (self.status.locationManagerStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {

        self.danglingBackgroundPermissionsRequest = YES;

        [self.locationManager requestAlwaysAuthorization];
        if (@available(iOS 14.0, *)) {
            RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                   backgroundPopupAvailable:NO
                                                                                          inForegroundPopup:self.status.inForegroundPopup
                                                                          userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
            [self updateStatus:status];
            // TODO: sync the user's location permissions action with the their permissions status here
        }

        // We set a flag that request has been made and start a timer. If we resign active we unset the timer.
        // When the timer fires and the flag has not been unset, we assume that app never resigned active.
        // Usually this means that the user has previously rejected the background permissions.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.danglingBackgroundPermissionsRequest) {
                if (@available(iOS 14.0, *)) {
                    RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithStatus:self.locationManager.authorizationStatus
                                                                                            backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                                    inForegroundPopup:self.status.inForegroundPopup
                                                                                    userRejectedBackgroundPermissions:YES];
                    [self updateStatus:status];
                }
            }
            self.danglingBackgroundPermissionsRequest = NO;
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
                                                                          userRejectedBackgroundPermissions: self.status.userRejectedBackgroundPermissions];
            [self updateStatus:status];
        }
        // TODO: sync the user's location permissions action with the their permissions status here
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
                                                                                 userRejectedBackgroundPermissions: YES];
                [self updateStatus:newStatus];
            }
        }
    }

    self.inBackgroundLocationPopUp = NO;
}


- (void)applicationWillResignActive {
    if (self.danglingBackgroundPermissionsRequest) {
        self.inBackgroundLocationPopUp = YES;
    }
    self.danglingBackgroundPermissionsRequest = NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    RadarLocationPermissionStatus *newStatus = [[RadarLocationPermissionStatus alloc] initWithStatus:status
                                                                              backgroundPopupAvailable:self.status.backgroundPopupAvailable
                                                                                     // any change in status will always result in the in foreground popup closing
                                                                                     inForegroundPopup:NO
                                                                     userRejectedBackgroundPermissions: 
                                                                     self.status.userRejectedBackgroundPermissions || (status == kCLAuthorizationStatusDenied)];
    [self updateStatus:newStatus];
}

- (RadarLocationPermissionStatus *)getLocationPermissionStatus {
    if (@available(iOS 14.0, *)) {
        return self.status;
    }
    return nil;
}


@end
