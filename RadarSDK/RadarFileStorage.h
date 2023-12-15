//
//  RadarFileStorage.h
//  RadarSDK
//
//  Created by Kenny Hu on 12/6/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarFileStorage : NSObject


- (NSData *)readFileAtPath:(NSString *)filePath;

- (void)writeData:(NSData *)data toFileAtPath:(NSString *)filePath;

- (void)deleteFileAtPath:(NSString *)filePath;

- (NSArray<NSString *> *)allFilesInDirectory:(NSString *)directoryPath;

- (NSArray<NSString *> *)allFilesInDirectory:(NSString *)directoryPath withComparator:(NSComparator)comparator;

@end
