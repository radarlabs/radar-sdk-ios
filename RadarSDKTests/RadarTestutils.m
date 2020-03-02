//
//  RadarTestUtils.m
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarTestUtils.h"

@implementation RadarTestUtils

+ (NSDictionary *)jsonDictionaryFromResource:(NSString *)resource {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:resource ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *deserializationError = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&deserializationError];
    NSDictionary *jsonDict = (NSDictionary *)jsonObj;
    return jsonDict;
}

@end
