//
//  RadarRouteMatrix.m
//  Library
//
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#import "RadarRouteMatrix.h"
#import "RadarRoute+Internal.h"
#import "RadarRouteMatrix+Internal.h"

@implementation RadarRouteMatrix

- (nullable instancetype)initWithMatrix:(nullable NSArray<NSArray<RadarRoute *> *> *)matrix {
    self = [super init];
    if (self) {
        _matrix = matrix;
    }
    return self;
}

- (nullable instancetype)initWithObject:(_Nonnull id)object {
    if (![object isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSArray *rows = (NSArray *)object;

    NSMutableArray<NSMutableArray<RadarRoute *> *> *matrix = [NSMutableArray arrayWithCapacity:rows.count];

    for (int i = 0; i < rows.count; i++) {
        NSArray *col = rows[i];
        NSMutableArray<RadarRoute *> *routes = [NSMutableArray arrayWithCapacity:col.count];
        for (int j = 0; j < col.count; j++) {
            RadarRoute *route = [[RadarRoute alloc] initWithObject:col[j]];
            routes[j] = route;
        }
        matrix[i] = routes;
    }

    return [[RadarRouteMatrix alloc] initWithMatrix:matrix];
}

- (RadarRoute *_Nullable)routeBetweenOriginIndex:(NSUInteger)originIndex destinationIndex:(NSUInteger)destinationIndex {
    if (originIndex >= self.matrix.count) {
        return nil;
    }

    NSArray<RadarRoute *> *routes = self.matrix[originIndex];

    if (destinationIndex >= routes.count) {
        return nil;
    }

    return routes[destinationIndex];
}

- (NSArray *)arrayValue {
    NSMutableArray<NSMutableArray<NSDictionary *> *> *rows = [NSMutableArray arrayWithCapacity:self.matrix.count];
    for (int i = 0; i < self.matrix.count; i++) {
        NSArray<RadarRoute *> *routes = self.matrix[i];
        NSMutableArray<NSDictionary *> *col = [NSMutableArray arrayWithCapacity:routes.count];
        for (int j = 0; j < routes.count; j++) {
            RadarRoute *route = routes[j];
            col[j] = [route dictionaryValue];
        }
        rows[i] = col;
    }
    return rows;
}

@end
