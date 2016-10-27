//
//  RadarUser.h
//  RadarSDK
//
//  Copyright © 2016 Radar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarUser : NSObject

- (instancetype _Nullable)initWithId:(NSString * _Nonnull)_id userId:(NSString * _Nonnull)userId description:(NSString * _Nullable)description;

/**
 * @abstract The unique ID for the user provided by Radar.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *_id;

/**
 * @abstract The external unique ID for the user in your database, provided when you started tracking the user.
 */
@property (nonnull, copy, nonatomic, readonly) NSString *userId;

/**
 * @abstract An optional description for the user, provided when you started tracking the user. Not to be confused with the NSObject description property.
 */
@property (nullable, copy, nonatomic, readonly) NSString *_description;

@end
