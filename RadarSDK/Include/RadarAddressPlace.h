//
//  RadarAddressPlace.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A place on the grounds of an enriched address.
 */
@interface RadarAddressPlace : NSObject

/**
 The name of the place.
 */
@property (copy, nonatomic, readonly) NSString *name;

/**
 The categories of the place.
 */
@property (copy, nonatomic, readonly) NSArray<NSString *> *categories;

- (NSDictionary *_Nonnull)dictionaryValue;

@end

NS_ASSUME_NONNULL_END
