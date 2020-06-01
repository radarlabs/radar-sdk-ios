//
//  RadarMacros.h
//  RadarSDKTests
//
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif

#define weakify(var) __weak typeof(var) RadarWeak_##var = var;

#define strongify(var)                                                                                                                                                             \
    _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"") __strong typeof(var) var = RadarWeak_##var;                                                  \
    _Pragma("clang diagnostic pop")

#define strongify_else_return(var)                                                                                                                                                 \
    strongify(var);                                                                                                                                                                \
    if (!var) {                                                                                                                                                                    \
        return;                                                                                                                                                                    \
    }
