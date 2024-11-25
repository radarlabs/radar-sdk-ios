//
//  RadarLocationPermissionsManager.m
//  RadarSDK
//
//  Created by Kenny Hu on 5/8/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarLocationPermissionManager.h"
#import "RadarLocationPermissionStatus+Internal.h"
#import "RadarDelegateHolder.h"
#import "RadarLogger.h"
#import "RadarLocationPermissionStatus.h"

@interface RadarLocationPermissionManager ()

@property (assign, nonatomic) BOOL danglingBackgroundPermissionRequest;
@property (assign, nonatomic) BOOL inBackgroundLocationPopUp;
@property (nullable, nonatomic, copy) RadarLocationPermissionCompletionHandler completionHandler;
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
        } else{
            if (@available(iOS 14.0, *)) {
                // need to improve this to handle the case where the app is initilized with some existing state
                RadarLocationPermissionAccuracy accuracy = [RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy:self.locationManager.accuracyAuthorization];
                switch (self.locationManager.authorizationStatus) {
                    case kCLAuthorizationStatusAuthorizedWhenInUse:
                        self.status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:[RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy:self.locationManager.accuracyAuthorization]
                                                                        permissionGranted:RadarPermissionLevelForeground
                                                                        requestAvailable:RadarPermissionLevelBackground];
                        break;
                    case kCLAuthorizationStatusAuthorizedAlways:
                        self.status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:[RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy:self.locationManager.accuracyAuthorization]
                                                                        permissionGranted:RadarPermissionLevelBackground
                                                                        requestAvailable:RadarPermissionLevelNone];
                        break;
                    case kCLAuthorizationStatusDenied:
                        self.status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:RadarPermissionAccuracyUnknown
                                                                        permissionGranted:RadarPermissionLevelUnknown
                                                                        requestAvailable:RadarPermissionLevelNone];
                        break;
                    case kCLAuthorizationStatusRestricted:
                        self.status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:RadarPermissionAccuracyUnknown
                                                                        permissionGranted:RadarPermissionLevelUnknown
                                                                        requestAvailable:RadarPermissionLevelNone];
                        break;
                    default:
                        self.status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:RadarPermissionAccuracyUnknown
                                                                        permissionGranted:RadarPermissionLevelUnknown
                                                                        requestAvailable:RadarPermissionLevelUnknown];
                        break;
                }
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
    // TODO: sync the user's state with the new permission status here, do i need to? esp with the accuracy hook?
    return self;
}

- (void)updateStatus:(RadarLocationPermissionStatus *)status {
    self.status = status;
    [RadarLocationPermissionStatus radarLocationPermissionStatus:status];
    if (@available(iOS 14.0, *)) {
        [[RadarDelegateHolder sharedInstance] didUpdateLocationPermissionStatus:self.status];
    }
    if (self.completionHandler) {
        self.completionHandler(self.status);
        self.completionHandler = nil;
    }
}

// do we still want to expose this?
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

- (void)requestBackgroundLocationPermissionWithCompletionHandler:(RadarLocationPermissionCompletionHandler)completionHandler {
    if (!self.radarSDKLocationPermission) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelError message:@"RadarSDKLocationPermission not found"];
        return completionHandler(self.status);
    }

    if (self.locationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.completionHandler = completionHandler;

        self.danglingBackgroundPermissionRequest = YES;
        NSLog(@"requesting background");
        [RadarLocationPermissionManager setUserRequestedBackgroundPermission:YES];
        [self.radarSDKLocationPermission requestBackgroundPermission];

        // We set a flag that request has been made and start a timer. If we resign active we unset the timer.
        // When the timer fires and the flag has not been unset, we assume that app never resigned active.
        // Usually this means that the user has previously rejected the background permission.
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           if (self.danglingBackgroundPermissionRequest) {
               if (@available(iOS 14.0, *)) {
                    [RadarLocationPermissionManager setUserDeniedLocationPermission:YES];
                    RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:[RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy: self.locationManager.accuracyAuthorization]
                                                                                                  permissionGranted:[RadarLocationPermissionStatus radarLocationPermissionLevelFromCLLocationAuthorizationStatus:self.locationManager.authorizationStatus]
                                                                                                   requestAvailable: RadarPermissionLevelNone];
                   [self updateStatus:status];
               }
           }
           self.danglingBackgroundPermissionRequest = NO;
       });
    } else {
        return completionHandler(self.status);
    }
}


- (void)requestForegroundLocationPermissionWithCompletionHandler:(RadarLocationPermissionCompletionHandler)completionHandler {
    
    if (self.locationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        self.completionHandler = completionHandler;
        [RadarLocationPermissionManager setUserRequestedForegroundPermission:YES];
        [self.locationManager requestWhenInUseAuthorization];
    } else {
        return completionHandler(self.status);
    } 
}

- (void)applicationDidBecomeActive {
    // we need to handle the case of double updates, we only want to update the status if and only if we are coming back from a popup and the status has changed.
    if (self.inBackgroundLocationPopUp) {

        if (@available(iOS 14.0, *)) {
            CLAuthorizationStatus status = self.locationManager.authorizationStatus;
           if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
               // if the status did not changed, we update the status here, otherwise we will update it in the delegate method
                    [RadarLocationPermissionManager setUserDeniedLocationPermission:YES];
                    RadarLocationPermissionStatus *status = [[RadarLocationPermissionStatus alloc] initWithAccuracy:[RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy: self.locationManager.accuracyAuthorization]
                                                                                                 permissionGranted:[RadarLocationPermissionStatus radarLocationPermissionLevelFromCLLocationAuthorizationStatus:self.locationManager.authorizationStatus]
                                                                                                   requestAvailable: RadarPermissionLevelNone];
                   [self updateStatus:status];
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
    NSLog(@"didChangeAuthorizationStatus");

    if (status == kCLAuthorizationStatusDenied) {
        [RadarLocationPermissionManager setUserRequestedForegroundPermission:YES];
        [RadarLocationPermissionManager setUserDeniedLocationPermission:YES];
    }

    // do we want to hardcode accuracy to unknown fi we do not yet have any other permission?
    RadarLocationPermissionStatus *newStatus = [[RadarLocationPermissionStatus alloc] initWithAccuracy:[RadarLocationPermissionStatus radarLocationPermissionAccuracyFromCLLocationAccuracy: self.locationManager.accuracyAuthorization]
                                                                                    permissionGranted:[RadarLocationPermissionStatus radarLocationPermissionLevelFromCLLocationAuthorizationStatus:status]
                                                                                    requestAvailable:[self inferRequestAvalible]];
        //RadarLocationPermissionStatus *newStatus = [[RadarLocationPermissionStatus alloc] initWithAccuracy:RadarPermissionAccuracyUnknown
                                                                                     //permissionGranted:RadarPermissionLevelUnknown
                                                                                      //requestAvailable:RadarPermissionLevelUnknown];
    
    
    // initWithStatus:status
    //                                                                           backgroundPopupAvailable:self.status.backgroundPopupAvailable
    //                                                                                  // any change in status will always result in the in foreground popup closing
    //                                                                                  inForegroundPopup:NO
    //                                                                  userRejectedBackgroundPermission: 
    //                                                                  self.status.userRejectedBackgroundPermission || (status == kCLAuthorizationStatusDenied)];
    [self updateStatus:newStatus];
}

- (RadarLocationPermissionLevel)inferRequestAvalible {
    RadarLocationPermissionLevel level = RadarPermissionLevelNone;

    switch (self.locationManager.authorizationStatus) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if ([RadarLocationPermissionManager userRequestedBackgroundPermission] || [RadarLocationPermissionManager userDeniedLocationPermission]) {
                level = RadarPermissionLevelNone;
            } else {
                level = RadarPermissionLevelBackground;
            }
            break;
        case kCLAuthorizationStatusDenied:
            level = RadarPermissionLevelNone;
            break;
        case kCLAuthorizationStatusNotDetermined:
            if ([RadarLocationPermissionManager userRequestedForegroundPermission]) {
                level = RadarPermissionLevelNone;
            } else {
                level = RadarPermissionLevelForeground;
            }
            break;
        default:
            level = RadarPermissionLevelNone;
            break;
    }
    return level;
}

- (RadarLocationPermissionStatus *)getLocationPermissionStatus {
    if (@available(iOS 14.0, *)) {
        return self.status;
    }
    return nil;
}

+ (void)setUserDeniedLocationPermission:(BOOL)userDeniedLocationPermission {
    [[NSUserDefaults standardUserDefaults] setBool:userDeniedLocationPermission forKey:@"radar-user-denied-location-permission"];
}

+ (BOOL)userDeniedLocationPermission {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults dictionaryRepresentation].allKeys containsObject:@"radar-user-denied-location-permission"]) {
        return [defaults boolForKey:@"radar-user-denied-location-permission"];
    } else {
        return NO; 
    }
}

+ (void)setUserRequestedForegroundPermission:(BOOL)userRequestedForegroundPermission {
    [[NSUserDefaults standardUserDefaults] setBool:userRequestedForegroundPermission forKey:@"radar-user-requested-foreground-permission"];
}

+ (BOOL)userRequestedForegroundPermission {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults dictionaryRepresentation].allKeys containsObject:@"radar-user-requested-foreground-permission"]) {
        return [defaults boolForKey:@"radar-user-requested-foreground-permission"];
    } else {
        return NO; 
    }
}

+ (void)setUserRequestedBackgroundPermission:(BOOL)userRequestedBackgroundPermission {
    [[NSUserDefaults standardUserDefaults] setBool:userRequestedBackgroundPermission forKey:@"radar-user-requested-background-permission"];
}

+ (BOOL)userRequestedBackgroundPermission {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults dictionaryRepresentation].allKeys containsObject:@"radar-user-requested-background-permission"]) {
        return [defaults boolForKey:@"radar-user-requested-background-permission"];
    } else {
        return NO; 
    }
}


@end
