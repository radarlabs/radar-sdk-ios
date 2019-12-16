//
//  RadarAddressConfidence.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, RadarAddressConfidence) {
    RadarAddressConfidenceExact,
    RadarAddressConfidenceInterpolated,
    RadarAddressConfidenceFallback
};
