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
typedef void (^_Nonnull RadarIndoorsSurveyCompletionHandler)(NSString *_Nullable result, CLLocation *_Nullable locationAtStartOfSurvey);

#import "RadarIndoorSurvey.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarSDKIndoors : NSObject

/**
 Performs an indoor survey to collect Bluetooth and sensor data.
 */
+ (void)doIndoorSurvey:(NSString *)placeLabel
             forLength:(int)surveyLengthSeconds
        isWhereAmIScan:(BOOL)isWhereAmIScan
     completionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END