#import <Foundation/Foundation.h>

@interface RadarFileSystem : NSObject

- (NSData *)readFileAtPath:(NSString *)filePath;
- (void)writeData:(NSData *)data toFileAtPath:(NSString *)filePath;

@end