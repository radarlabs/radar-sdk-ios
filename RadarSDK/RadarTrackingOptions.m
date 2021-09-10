//
//  RadarTrackingOptions.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import "RadarTrackingOptions.h"

@implementation RadarTrackingOptions

NSString *const kDesiredStoppedUpdateInterval = @"desiredStoppedUpdateInterval";
NSString *const kDesiredMovingUpdateInterval = @"desiredMovingUpdateInterval";
NSString *const kDesiredSyncInterval = @"desiredSyncInterval";
NSString *const kDesiredAccuracy = @"desiredAccuracy";
NSString *const kStopDuration = @"stopDuration";
NSString *const kStopDistance = @"stopDistance";
NSString *const kStartTrackingAfter = @"startTrackingAfter";
NSString *const kStopTrackingAfter = @"stopTrackingAfter";
NSString *const kSync = @"sync";
NSString *const kReplay = @"replay";
NSString *const kShowBlueBar = @"showBlueBar";
NSString *const kUseStoppedGeofence = @"useStoppedGeofence";
NSString *const kStoppedGeofenceRadius = @"stoppedGeofenceRadius";
NSString *const kUseMovingGeofence = @"useMovingGeofence";
NSString *const kMovingGeofenceRadius = @"movingGeofenceRadius";
NSString *const kSyncGeofences = @"syncGeofences";
NSString *const kUseVisits = @"useVisits";
NSString *const kUseSignificantLocationChanges = @"useSignificantLocationChanges";
NSString *const kBeacons = @"beacons";

NSString *const kDesiredAccuracyHigh = @"high";
NSString *const kDesiredAccuracyMedium = @"medium";
NSString *const kDesiredAccuracyLow = @"low";

NSString *const kReplayStops = @"stops";
NSString *const kReplayNone = @"none";

NSString *const kSyncAll = @"all";
NSString *const kSyncStopsAndExits = @"stopsAndExits";
NSString *const kSyncNone = @"none";

+ (RadarTrackingOptions *)presetContinuous {
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.desiredStoppedUpdateInterval = 30;
    options.desiredMovingUpdateInterval = 30;
    options.desiredSyncInterval = 20;
    options.desiredAccuracy = RadarTrackingOptionsDesiredAccuracyHigh;
    options.stopDuration = 140;
    options.stopDistance = 70;
    options.startTrackingAfter = nil;
    options.stopTrackingAfter = nil;
    options.syncLocations = RadarTrackingOptionsSyncAll;
    options.replay = RadarTrackingOptionsReplayNone;
    options.showBlueBar = YES;
    options.useStoppedGeofence = NO;
    options.stoppedGeofenceRadius = 0;
    options.useMovingGeofence = NO;
    options.movingGeofenceRadius = 0;
    options.syncGeofences = NO;
    options.useVisits = NO;
    options.useSignificantLocationChanges = NO;
    options.beacons = NO;
    return options;
}

+ (RadarTrackingOptions *)presetResponsive {
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.desiredStoppedUpdateInterval = 0;
    options.desiredMovingUpdateInterval = 150;
    options.desiredSyncInterval = 20;
    options.desiredAccuracy = RadarTrackingOptionsDesiredAccuracyMedium;
    options.stopDuration = 140;
    options.stopDistance = 70;
    options.startTrackingAfter = nil;
    options.stopTrackingAfter = nil;
    options.syncLocations = RadarTrackingOptionsSyncAll;
    options.replay = RadarTrackingOptionsReplayStops;
    options.showBlueBar = NO;
    options.useStoppedGeofence = YES;
    options.stoppedGeofenceRadius = 100;
    options.useMovingGeofence = NO;
    options.movingGeofenceRadius = 0;
    options.syncGeofences = YES;
    options.useVisits = YES;
    options.useSignificantLocationChanges = YES;
    options.beacons = NO;
    return options;
}

+ (RadarTrackingOptions *)presetEfficient {
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.desiredStoppedUpdateInterval = 0;
    options.desiredMovingUpdateInterval = 0;
    options.desiredSyncInterval = 0;
    options.desiredAccuracy = RadarTrackingOptionsDesiredAccuracyMedium;
    options.stopDuration = 0;
    options.stopDistance = 0;
    options.startTrackingAfter = nil;
    options.stopTrackingAfter = nil;
    options.syncLocations = RadarTrackingOptionsSyncAll;
    options.replay = RadarTrackingOptionsReplayStops;
    options.showBlueBar = NO;
    options.useStoppedGeofence = NO;
    options.stoppedGeofenceRadius = 0;
    options.useMovingGeofence = NO;
    options.movingGeofenceRadius = 0;
    options.syncGeofences = YES;
    options.useVisits = YES;
    options.useSignificantLocationChanges = NO;
    options.beacons = NO;
    return options;
}

+ (NSString *)stringForDesiredAccuracy:(RadarTrackingOptionsDesiredAccuracy)desiredAccuracy {
    NSString *str;
    switch (desiredAccuracy) {
    case RadarTrackingOptionsDesiredAccuracyHigh:
        str = kDesiredAccuracyHigh;
        break;
    case RadarTrackingOptionsDesiredAccuracyMedium:
        str = kDesiredAccuracyMedium;
        break;
    case RadarTrackingOptionsDesiredAccuracyLow:
        str = kDesiredAccuracyLow;
        break;
    default:
        str = kDesiredAccuracyMedium;
    }
    return str;
}

+ (RadarTrackingOptionsDesiredAccuracy)desiredAccuracyForString:(NSString *)str {
    RadarTrackingOptionsDesiredAccuracy desiredAccuracy = RadarTrackingOptionsDesiredAccuracyMedium;
    if ([str isEqualToString:kDesiredAccuracyHigh]) {
        desiredAccuracy = RadarTrackingOptionsDesiredAccuracyHigh;
    } else if ([str isEqualToString:kDesiredAccuracyLow]) {
        desiredAccuracy = RadarTrackingOptionsDesiredAccuracyLow;
    }
    return desiredAccuracy;
}

+ (NSString *)stringForReplay:(RadarTrackingOptionsReplay)replay {
    NSString *str;
    switch (replay) {
    case RadarTrackingOptionsReplayStops:
        str = kReplayStops;
        break;
    case RadarTrackingOptionsReplayNone:
    default:
        str = kReplayNone;
    }
    return str;
}

+ (RadarTrackingOptionsReplay)replayForString:(NSString *)str {
    RadarTrackingOptionsReplay replay = RadarTrackingOptionsReplayNone;
    if ([str isEqualToString:kReplayStops]) {
        replay = RadarTrackingOptionsReplayStops;
    }
    return replay;
}

+ (NSString *)stringForSyncLocations:(RadarTrackingOptionsSyncLocations)sync {
    NSString *str;
    switch (sync) {
    case RadarTrackingOptionsSyncNone:
        str = kSyncNone;
        break;
    case RadarTrackingOptionsSyncStopsAndExits:
        str = kSyncStopsAndExits;
        break;
    case RadarTrackingOptionsSyncAll:
    default:
        str = kSyncAll;
    }
    return str;
}

+ (RadarTrackingOptionsSyncLocations)syncLocationsForString:(NSString *)str {
    RadarTrackingOptionsSyncLocations sync = RadarTrackingOptionsSyncAll;
    if ([str isEqualToString:kSyncStopsAndExits]) {
        sync = RadarTrackingOptionsSyncStopsAndExits;
    } else if ([str isEqualToString:kSyncNone]) {
        sync = RadarTrackingOptionsSyncNone;
    }
    return sync;
}

+ (RadarTrackingOptions *)trackingOptionsFromDictionary:(NSDictionary *)dict {
    RadarTrackingOptions *options = [RadarTrackingOptions new];
    options.desiredStoppedUpdateInterval = [dict[kDesiredStoppedUpdateInterval] intValue];
    options.desiredMovingUpdateInterval = [dict[kDesiredMovingUpdateInterval] intValue];
    options.desiredSyncInterval = [dict[kDesiredSyncInterval] intValue];
    options.desiredAccuracy = [RadarTrackingOptions desiredAccuracyForString:dict[kDesiredAccuracy]];
    options.stopDuration = [dict[kStopDuration] intValue];
    options.stopDistance = [dict[kStopDistance] intValue];
    options.startTrackingAfter = dict[kStartTrackingAfter];
    options.stopTrackingAfter = dict[kStopTrackingAfter];
    options.syncLocations = [RadarTrackingOptions syncLocationsForString:dict[kSync]];
    options.replay = [RadarTrackingOptions replayForString:dict[kReplay]];
    options.showBlueBar = [dict[kShowBlueBar] boolValue];
    options.useStoppedGeofence = [dict[kUseStoppedGeofence] boolValue];
    options.stoppedGeofenceRadius = [dict[kStoppedGeofenceRadius] intValue];
    options.useMovingGeofence = [dict[kUseMovingGeofence] boolValue];
    options.movingGeofenceRadius = [dict[kMovingGeofenceRadius] intValue];
    options.syncGeofences = [dict[kSyncGeofences] boolValue];
    options.useVisits = [dict[kUseVisits] boolValue];
    options.useSignificantLocationChanges = [dict[kUseSignificantLocationChanges] boolValue];
    options.beacons = [dict[kBeacons] boolValue];
    return options;
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[kDesiredStoppedUpdateInterval] = @(self.desiredStoppedUpdateInterval);
    dict[kDesiredMovingUpdateInterval] = @(self.desiredMovingUpdateInterval);
    dict[kDesiredSyncInterval] = @(self.desiredSyncInterval);
    dict[kDesiredAccuracy] = [RadarTrackingOptions stringForDesiredAccuracy:self.desiredAccuracy];
    dict[kStopDuration] = @(self.stopDuration);
    dict[kStopDistance] = @(self.stopDistance);
    dict[kStartTrackingAfter] = self.startTrackingAfter;
    dict[kStopTrackingAfter] = self.stopTrackingAfter;
    dict[kSync] = [RadarTrackingOptions stringForSyncLocations:self.syncLocations];
    dict[kReplay] = [RadarTrackingOptions stringForReplay:self.replay];
    dict[kShowBlueBar] = @(self.showBlueBar);
    dict[kUseStoppedGeofence] = @(self.useStoppedGeofence);
    dict[kStoppedGeofenceRadius] = @(self.stoppedGeofenceRadius);
    dict[kUseMovingGeofence] = @(self.useMovingGeofence);
    dict[kMovingGeofenceRadius] = @(self.movingGeofenceRadius);
    dict[kSyncGeofences] = @(self.syncGeofences);
    dict[kUseVisits] = @(self.useVisits);
    dict[kUseSignificantLocationChanges] = @(self.useSignificantLocationChanges);
    dict[kBeacons] = @(self.beacons);
    return dict;
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }

    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[RadarTrackingOptions class]]) {
        return NO;
    }

    RadarTrackingOptions *options = (RadarTrackingOptions *)object;

    return self.desiredStoppedUpdateInterval == options.desiredStoppedUpdateInterval && self.desiredMovingUpdateInterval == options.desiredMovingUpdateInterval &&
           self.desiredSyncInterval == options.desiredSyncInterval && self.desiredAccuracy == options.desiredAccuracy && self.stopDuration == options.stopDuration &&
           self.stopDistance == options.stopDistance &&
           (self.startTrackingAfter == nil ? options.startTrackingAfter == nil : [self.startTrackingAfter isEqual:options.startTrackingAfter]) &&
           (self.stopTrackingAfter == nil ? options.stopTrackingAfter == nil : [self.stopTrackingAfter isEqual:options.stopTrackingAfter]) &&
           self.syncLocations == options.syncLocations && self.replay == options.replay && self.showBlueBar == options.showBlueBar &&
           self.useStoppedGeofence == options.useStoppedGeofence && self.stoppedGeofenceRadius == options.stoppedGeofenceRadius &&
           self.useMovingGeofence == options.useMovingGeofence && self.movingGeofenceRadius == options.movingGeofenceRadius && self.syncGeofences == options.syncGeofences &&
           self.useVisits == options.useVisits && self.useSignificantLocationChanges == options.useSignificantLocationChanges && self.beacons == options.beacons;
}

@end
