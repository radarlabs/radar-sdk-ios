//
//  RadarCoordinate.h
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

/**
 Represents a location coordinate.
 */
@interface RadarCoordinate : NSObject

/**
 The coordinate.
 */
@property (assign, nonatomic, readonly) CLLocationCoordinate2D coordinate;

<<<<<<< HEAD
- (NSDictionary * _Nonnull)dictionaryValue;
=======
- (NSDictionary* _Nonnull)serialize;
>>>>>>> master

@end
