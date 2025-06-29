//
//  RadarSDKIndoors.h
//  RadarSDKIndoors
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

// Indoor survey completion handler
typedef void (^_Nonnull RadarIndoorsSurveyCompletionHandler)(NSString *_Nullable result, CLLocation *_Nonnull locationAtStartOfSurvey);

#import "RadarIndoorSurvey.h"

@interface RadarSDKIndoors : NSObject

/**
 Performs an indoor survey to collect Bluetooth and sensor data.
 */
+ (void)doIndoorSurvey:(NSString *)placeLabel
             forLength:(int)surveyLengthSeconds
        isWhereAmIScan:(BOOL)isWhereAmIScan
     completionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;

@end