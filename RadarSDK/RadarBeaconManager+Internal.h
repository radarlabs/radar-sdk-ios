//
//  RadarBeaconManager+Testing.h
//  Library
//
//  Created by Ping Xia on 5/1/20.
//  Copyright © 2020 Radar Labs, Inc. All rights reserved.
//

#import "RadarBeaconManager.h"
#import "RadarBeaconScanner.h"

NS_ASSUME_NONNULL_BEGIN

@interface RadarBeaconManager ()<RadarBeaconScannerDelegate>

@property (nonatomic, strong, nonnull) RadarBeaconScanner *beaconScanner;

@end

NS_ASSUME_NONNULL_END
