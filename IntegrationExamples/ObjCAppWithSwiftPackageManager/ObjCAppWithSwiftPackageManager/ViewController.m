//
//  ViewController.m
//  ObjCAppWithCocoaPods
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

#import "ViewController.h"
#import <Radar.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *radarBundle = [NSBundle bundleForClass:Radar.class];
    NSString *versionString = [radarBundle infoDictionary][@"CFBundleShortVersionString"];
    self.versionNumberLabel.text = versionString;
}


@end
