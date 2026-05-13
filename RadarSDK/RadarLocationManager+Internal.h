//
//  RadarLocationManager+Internal.h
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

#import "RadarLocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarLocationManager ()

- (void)clearImplementationSelectionForTesting;
- (void)forceImplementationSelectionForTestingUseSwift:(BOOL)useSwift;
- (NSString *_Nullable)selectedImplementationClassNameForTesting;

@end

NS_ASSUME_NONNULL_END
