//
//  ViewController.m
//  ObjCAppWithCocoaPods
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#import "ViewController.h"
@import RadarSDK;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.versionNumberLabel.text = Radar.sdkVersion;
}


@end
