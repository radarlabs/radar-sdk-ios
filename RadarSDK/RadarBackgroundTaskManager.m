//
//  RadarBackgroundTaskManager.m
//  RadarSDK
//
//  Copyright © 2019 Radar Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RadarBackgroundTaskManager.h"
#import "RadarLogger.h"
#import "RadarUtils.h"

@interface RadarBackgroundTaskManager ()

@property (nonnull, strong, nonatomic) NSMutableArray<NSNumber *> *backgroundTaskIdentifierNumbers;

@end

@implementation RadarBackgroundTaskManager

static NSString *const kBackgroundTaskName = @"radar";

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    if ([NSThread isMainThread]) {
        dispatch_once(&once, ^{
            sharedInstance = [self new];
        });
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_once(&once, ^{
                sharedInstance = [self new];
            });
        });
    }
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _backgroundTaskIdentifierNumbers = [NSMutableArray new];
    }
    return self;
}

- (void)startBackgroundTask {
    NSTimeInterval backgroundTimeRemaining = [RadarUtils backgroundTimeRemaining];
    NSTimeInterval duration = backgroundTimeRemaining > 170 ? 170 : backgroundTimeRemaining - 10;

    if (duration < 10) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug message:[NSString stringWithFormat:@"Background time expiring | duration = %f", duration]];

        return;
    }

    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [[UIApplication sharedApplication]
        beginBackgroundTaskWithName:kBackgroundTaskName
                  expirationHandler:^{
                      [[RadarLogger sharedInstance]
                          logWithLevel:RadarLogLevelDebug
                               message:[NSString stringWithFormat:@"Expiring background task | backgroundTaskIdentifier = %lu", (unsigned long)backgroundTaskIdentifier]];

                      [self endBackgroundTaskWithIdentifier:backgroundTaskIdentifier];
                  }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self endBackgroundTaskWithIdentifier:backgroundTaskIdentifier];
    });

    @synchronized(self) {
        [self.backgroundTaskIdentifierNumbers addObject:[NSNumber numberWithUnsignedLong:backgroundTaskIdentifier]];

        [[RadarLogger sharedInstance]
            logWithLevel:RadarLogLevelDebug
                 message:[NSString stringWithFormat:@"Started background task | backgroundTaskIdentifier = %lu; duration = %f", (unsigned long)backgroundTaskIdentifier, duration]];
    }
}

- (void)endBackgroundTasks {
    @synchronized(self) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Ending background tasks | self.backgroundTaskIdentifierNumbers.count = %lu",
                                                                              (unsigned long)self.backgroundTaskIdentifierNumbers.count]];

        for (NSNumber *backgroundTaskIdentifierNumber in self.backgroundTaskIdentifierNumbers) {
            UIBackgroundTaskIdentifier backgroundTaskIdentifier = [backgroundTaskIdentifierNumber unsignedLongValue];
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }

        [self.backgroundTaskIdentifierNumbers removeAllObjects];
    }
}

- (void)endBackgroundTaskWithIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier {
    @synchronized(self) {
        [[RadarLogger sharedInstance] logWithLevel:RadarLogLevelDebug
                                           message:[NSString stringWithFormat:@"Ending background task | backgroundTaskIdentifier = %lu", (unsigned long)backgroundTaskIdentifier]];

        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;

        NSNumber *backgroundTaskIdentifierNumber = [NSNumber numberWithUnsignedLong:backgroundTaskIdentifier];
        [self.backgroundTaskIdentifierNumbers removeObject:backgroundTaskIdentifierNumber];
    }
}

@end
