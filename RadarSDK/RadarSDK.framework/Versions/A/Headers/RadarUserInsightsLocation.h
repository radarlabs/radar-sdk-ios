//
//  RadarUserInsightsLocation.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 Represents a learned home or work location. For more information about Insights, see https://radar.io/documentation/insights.
 
 @see https://radar.io/documentation/insights
 */
@interface RadarUserInsightsLocation : NSObject

/**
 The types for learned locations.
 */
typedef NS_ENUM(NSInteger, RadarUserInsightsLocationType) {
    /// Unknown
    RadarUserInsightsLocationTypeUnknown NS_SWIFT_NAME(unknown),
    /// Home
    RadarUserInsightsLocationTypeHome NS_SWIFT_NAME(home),
    /// Office
    RadarUserInsightsLocationTypeOffice NS_SWIFT_NAME(office)
};

/**
 The confidence levels for learned locations.
 */
typedef NS_ENUM(NSInteger, RadarUserInsightsLocationConfidence) {
    /// Unknown confidence
    RadarUserInsightsLocationConfidenceNone NS_SWIFT_NAME(none) = 0,
    /// Low confidence
    RadarUserInsightsLocationConfidenceLow NS_SWIFT_NAME(low) = 1,
    /// Medium confidence
    RadarUserInsightsLocationConfidenceMedium NS_SWIFT_NAME(medium) = 2,
    /// High confidence
    RadarUserInsightsLocationConfidenceHigh NS_SWIFT_NAME(high) = 3
};

/**
 The type of the learned location.
 */
@property (assign, nonatomic, readonly) RadarUserInsightsLocationType type;

/**
 The learned location.
 */
@property (nonnull, strong, nonatomic, readonly) CLLocation *location;

/**
 The confidence level of the learned location.
 */
@property (assign, nonatomic, readonly) RadarUserInsightsLocationConfidence confidence;

/**
 The datetime when the learned location was updated.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *updatedAt;

@end
