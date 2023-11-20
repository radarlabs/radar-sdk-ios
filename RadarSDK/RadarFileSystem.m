//
//  RadarFileSystem.m
//  RadarSDK
//
//  Created by Kenny Hu on 11/20/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarFileSystem.h"

@implementation RadarFileSystem

- (NSData *)readFileAtPath:(NSString *)filePath {
    __block NSData *fileData = nil;

    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateReadingItemAtURL:[NSURL fileURLWithPath:filePath] options:0 error:nil byAccessor:^(NSURL *newURL) {
        fileData = [NSData dataWithContentsOfURL:newURL];
    }];

    return fileData;
}

- (void)writeData:(NSData *)data toFileAtPath:(NSString *)filePath {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newURL) {
        [data writeToURL:newURL atomically:YES];
    }];
}

@end

