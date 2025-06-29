//
//  RadarSDKIndoors.m
//  RadarSDKIndoors
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

#import "RadarSDKIndoors.h"

@implementation RadarSDKIndoors

+ (void)doIndoorSurvey:(NSString *)placeLabel
             forLength:(int)surveyLengthSeconds
        isWhereAmIScan:(BOOL)isWhereAmIScan
     completionHandler:(RadarIndoorsSurveyCompletionHandler)completionHandler {
    
    [[RadarIndoorSurvey sharedInstance] start:placeLabel
                                    forLength:surveyLengthSeconds
                            withKnownLocation:nil
                               isWhereAmIScan:isWhereAmIScan
                        withCompletionHandler:completionHandler];
}

@end 