//
//  Radar+Internal.h
//  RadarSDK
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "Radar.h"
#import "RadarLocationProviding.h"
#import "RadarAPIClient.h"
#import <Foundation/Foundation.h>

@interface Radar ()

+ (id<RadarLocationProviding>)locationProvider;

+ (void)sendLog:(RadarLogLevel)level type:(RadarLogType)type message:(NSString *_Nonnull)message;

+ (void)flushLogs;

+ (void)logOpenedAppConversion;

+ (void)logConversionWithNotification:(UNNotificationRequest *_Nonnull)request 
                            eventName:(NSString *_Nonnull)eventName
                     conversionSource:(NSString *_Nullable)conversionSource 
                       deliveredAfter:(NSDate *_Nullable)deliveredAfter;

+ (void)sendLogConversionRequestWithName:(NSString * _Nonnull) name
                                metadata:(NSDictionary * _Nullable) metadata
                                campaign:(NSString*_Nullable)campaign
                       completionHandler:(RadarLogConversionCompletionHandler) completionHandler;

+ (void)logOpenedAppConversionWithNotification:(UNNotificationRequest *_Nonnull)request 
                              conversionSource:(NSString *_Nullable)conversionSource;

+ (NSString *_Nonnull)stringForMotionAuthorizationStatus;

// API client wrappers for Swift interop (Swift RadarAPIClient shadows ObjC RadarAPIClient)
+ (void)apiTrackWithLocation:(CLLocation *_Nonnull)location
                     stopped:(BOOL)stopped
                  foreground:(BOOL)foreground
                      source:(RadarLocationSource)source
                    replayed:(BOOL)replayed
                     beacons:(NSArray<RadarBeacon *> *_Nullable)beacons
                  indoorScan:(NSString *_Nullable)indoorScan
           completionHandler:(RadarTrackAPICompletionHandler _Nonnull)completionHandler;

+ (void)apiSearchBeaconsNear:(CLLocation *_Nonnull)near
                      radius:(int)radius
                       limit:(int)limit
           completionHandler:(RadarSearchBeaconsAPICompletionHandler _Nonnull)completionHandler
           NS_SWIFT_NAME(apiSearchBeacons(near:radius:limit:completionHandler:));

@end
