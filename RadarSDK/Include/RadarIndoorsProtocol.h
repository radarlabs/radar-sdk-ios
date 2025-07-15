//
//  RadarIndoorsProtocol.h
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Radar.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RadarIndoorsProtocol<NSObject>

+ (void)startIndoorSurvey:(NSString *)placeLabel
                forLength:(int)surveyLengthSeconds
        withKnownLocation:(CLLocation *_Nullable)knownLocation
           isWhereAmIScan:(BOOL)isWhereAmIScan
        completionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
