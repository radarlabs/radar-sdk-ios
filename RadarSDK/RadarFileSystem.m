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

// //init temp file path
// - (instancetype)init {
//     self = [super init];
//     if (self) {
//         NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//         NSString *logFileName = @"RadarTempLogs.txt";
//         self.tempFilePath = [documentsDirectory stringByAppendingPathComponent:logFileName];
//     }
//     return self;
// }

// + (instancetype)sharedInstance {
//     static dispatch_once_t once;
//     static id sharedInstance;
//     dispatch_once(&once, ^{
//         sharedInstance = [self new];
//     });
//     return sharedInstance;
// }

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

@end

