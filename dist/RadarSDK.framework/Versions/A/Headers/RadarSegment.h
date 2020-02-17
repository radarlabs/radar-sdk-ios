//
//  RadarSegment.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a user segment.
 */
@interface RadarSegment : NSObject

/**
 The description of the segment.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_description;

/**
 The external ID of the segment.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *externalId;

- (NSDictionary * _Nonnull)toDictionary;

@end

NS_ASSUME_NONNULL_END
