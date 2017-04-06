//
//  RadarUserInsightsLocation.h
//  RadarSDK
//
//  Copyright © 2017 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface RadarUserInsightsLocation : NSObject

/**
 * The types for learned locations.
 */
typedef NS_ENUM(NSInteger, RadarUserInsightsLocationType) {
    RadarUserInsightsLocationTypeUnknown NS_SWIFT_NAME(unknown),
    RadarUserInsightsLocationTypeHome NS_SWIFT_NAME(home),
    RadarUserInsightsLocationTypeOffice NS_SWIFT_NAME(office)
};

/**
 * The confidence levels for learned locations.
 */
typedef NS_ENUM(NSInteger, RadarUserInsightsLocationConfidence) {
    RadarUserInsightsLocationConfidenceNone NS_SWIFT_NAME(none) = 0,
    RadarUserInsightsLocationConfidenceLow NS_SWIFT_NAME(low) = 1,
    RadarUserInsightsLocationConfidenceMedium NS_SWIFT_NAME(medium) = 2,
    RadarUserInsightsLocationConfidenceHigh NS_SWIFT_NAME(high) = 3
};

/**
 * @abstract The type of the learned location.
 */
@property (assign, nonatomic, readonly) RadarUserInsightsLocationType type;

/**
 * @abstract The learned location.
 */
@property (nonnull, strong, nonatomic, readonly) CLLocation *location;

/**
 * @abstract The confidence level of the learned location.
 */
@property (assign, nonatomic, readonly) RadarUserInsightsLocationConfidence confidence;

/**
 * @abstract The datetime when the learned location was updated.
 */
@property (nonnull, copy, nonatomic, readonly) NSDate *updatedAt;

@end
