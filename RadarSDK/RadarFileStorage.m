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

- (void)appendData:(NSData *)data toFileAtPath:(NSString *)filePath {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    //TODO: not very sure if the option is correct, need to check
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newURL) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:newURL error:nil];
        if (!fileHandle) {
            [[NSFileManager defaultManager] createFileAtPath:[newURL path] contents:nil attributes:nil];
            fileHandle = [NSFileHandle fileHandleForWritingToURL:newURL error:nil];
        }
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }];
}


- (void)deleteFileAtPath:(NSString *)filePath {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateWritingItemAtURL:[NSURL fileURLWithPath:filePath] options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
    }];
}

@end

