//
//  RadarFileSystem.h
//  RadarSDK
//
//  Created by Kenny Hu on 11/20/23.
//  Copyright © 2023 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarFileSystem : NSObject

- (NSData *)readFileAtPath:(NSString *)filePath;

- (void)writeData:(NSData *)data toFileAtPath:(NSString *)filePath;

- (void)deleteFileAtPath:(NSString *)filePath;

@end
