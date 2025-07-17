//
//  RadarTripOrder.m
//  RadarSDK
//
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import "RadarTripOrder.h"
#import "RadarUtils.h"

@implementation RadarTripOrder

- (instancetype _Nullable)initWithId:(NSString *_Nonnull)_id
                                guid:(NSString *_Nullable)guid
                        handoffMode:(NSString *_Nullable)handoffMode
                              status:(RadarTripOrderStatus)status
                             firedAt:(NSDate *_Nullable)firedAt
                       firedAttempts:(NSNumber *_Nullable)firedAttempts
                         firedReason:(NSString *_Nullable)firedReason
                           updatedAt:(NSDate *_Nonnull)updatedAt {
    self = [super init];
    if (self) {
        __id = _id;
        _guid = guid;
        _handoffMode = handoffMode;
        _status = status;
        _firedAt = firedAt;
        _firedAttempts = firedAttempts;
        _firedReason = firedReason;
        _updatedAt = updatedAt;
    }
    return self;
}

- (instancetype _Nullable)initWithObject:(NSObject *)object {
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSDictionary *dict = (NSDictionary *)object;

    NSString *_id;
    NSString *guid;
    NSString *handoffMode;
    RadarTripOrderStatus status = RadarTripOrderStatusUnknown;
    NSDate *firedAt;
    NSNumber *firedAttempts;
    NSString *firedReason;
    NSDate *updatedAt;

    id idObj = dict[@"id"];
    if (idObj && [idObj isKindOfClass:[NSString class]]) {
        _id = (NSString *)idObj;
    }

    id guidObj = dict[@"guid"];
    if (guidObj && [guidObj isKindOfClass:[NSString class]]) {
        guid = (NSString *)guidObj;
    }

    id handoffModeObj = dict[@"handoffMode"];
    if (handoffModeObj && [handoffModeObj isKindOfClass:[NSString class]]) {
        handoffMode = (NSString *)handoffModeObj;
    }

    id statusObj = dict[@"status"];
    if (statusObj && [statusObj isKindOfClass:[NSString class]]) {
        NSString *statusStr = (NSString *)statusObj;
        if ([statusStr isEqualToString:@"pending"]) {
            status = RadarTripOrderStatusPending;
        } else if ([statusStr isEqualToString:@"fired"]) {
            status = RadarTripOrderStatusFired;
        } else if ([statusStr isEqualToString:@"canceled"]) {
            status = RadarTripOrderStatusCanceled;
        } else if ([statusStr isEqualToString:@"completed"]) {
            status = RadarTripOrderStatusCompleted;
        }
    }

    id firedAtObj = dict[@"firedAt"];
    if (firedAtObj && [firedAtObj isKindOfClass:[NSString class]]) {
        NSString *firedAtStr = (NSString *)firedAtObj;
        firedAt = [RadarUtils.isoDateFormatter dateFromString:firedAtStr];
    }

    id firedAttemptsObj = dict[@"firedAttempts"];
    if (firedAttemptsObj && [firedAttemptsObj isKindOfClass:[NSNumber class]]) {
        firedAttempts = (NSNumber *)firedAttemptsObj;
    }

    id firedReasonObj = dict[@"firedReason"];
    if (firedReasonObj && [firedReasonObj isKindOfClass:[NSString class]]) {
        firedReason = (NSString *)firedReasonObj;
    }

    id updatedAtObj = dict[@"updatedAt"];
    if (updatedAtObj && [updatedAtObj isKindOfClass:[NSString class]]) {
        NSString *updatedAtStr = (NSString *)updatedAtObj;
        updatedAt = [RadarUtils.isoDateFormatter dateFromString:updatedAtStr];
    }

    if (_id && updatedAt) {
        return [[RadarTripOrder alloc] initWithId:_id
                                             guid:guid
                                     handoffMode:handoffMode
                                           status:status
                                          firedAt:firedAt
                                    firedAttempts:firedAttempts
                                      firedReason:firedReason
                                        updatedAt:updatedAt];
    }

    return nil;
}

+ (NSArray<RadarTripOrder *> *_Nullable)ordersFromObject:(id _Nonnull)object {
    if (!object || ![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *ordersArr = (NSArray *)object;
    NSMutableArray<RadarTripOrder *> *mutableOrders = [NSMutableArray<RadarTripOrder *> new];

    for (id orderObj in ordersArr) {
        RadarTripOrder *order = [[RadarTripOrder alloc] initWithObject:orderObj];
        if (!order) {
            return nil;
        }
        [mutableOrders addObject:order];
    }

    return mutableOrders;
}

+ (NSArray<NSDictionary *> *)arrayForOrders:(NSArray<RadarTripOrder *> *)orders {
    if (!orders) {
        return nil;
    }

    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:orders.count];
    for (RadarTripOrder *order in orders) {
        NSDictionary *dict = [order dictionaryValue];
        [arr addObject:dict];
    }
    return arr;
}

+ (NSString *)stringForStatus:(RadarTripOrderStatus)status {
    switch (status) {
    case RadarTripOrderStatusPending:
        return @"pending";
    case RadarTripOrderStatusFired:
        return @"fired";
    case RadarTripOrderStatusCanceled:
        return @"canceled";
    case RadarTripOrderStatusCompleted:
        return @"completed";
    default:
        return @"unknown";
    }
}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict setValue:self._id forKey:@"id"];
    [dict setValue:self.guid forKey:@"guid"];
    [dict setValue:self.handoffMode forKey:@"handoffMode"];
    [dict setValue:[RadarTripOrder stringForStatus:self.status] forKey:@"status"];
    if (self.firedAt) {
        NSString *firedAtString = [RadarUtils.isoDateFormatter stringFromDate:self.firedAt];
        [dict setValue:firedAtString forKey:@"firedAt"];
    }
    [dict setValue:self.firedAttempts forKey:@"firedAttempts"];
    [dict setValue:self.firedReason forKey:@"firedReason"];
    NSString *updatedAtString = [RadarUtils.isoDateFormatter stringFromDate:self.updatedAt];
    [dict setValue:updatedAtString forKey:@"updatedAt"];
    return dict;
}

@end 