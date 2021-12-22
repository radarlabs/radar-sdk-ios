//
//  RadarFraud+Internal.h
//  RadarSDK
//
//  Created by Jason Tibbetts on 12/22/21.
//  Copyright © 2021 Radar Labs, Inc. All rights reserved.
//

#ifndef RadarFraud_Internal_h
#define RadarFraud_Internal_h

#import "RadarFraud+Internal.h"

@interface RadarFraud ()

- (instancetype _Nonnull)initWithProxy:(bool)proxy
                                mocked:(bool)mocked;

@end

#endif /* RadarFraud_Internal_h */
