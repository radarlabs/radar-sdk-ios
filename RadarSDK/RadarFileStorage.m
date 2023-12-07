//
//  RadarFileStorage.m
//  RadarSDK
//
//  Created by Kenny Hu on 12/6/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RadarFileStorage.h"

@implementation RadarFileStorage



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
        [data writeToURL:newURL options:NSDataWritingAtomic error:nil];
    }];
}

- (void)deleteFileAtPath:(NSString *)filePath {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
    }];
}

- (NSArray<NSString *> *)allFilesInDirectory:(NSString *)directoryPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    
    if (error) {
        NSLog(@"Failed to get files in directory: %@", [error localizedDescription]);
        return nil;
    }
    
    return [files sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];;
}

@end

