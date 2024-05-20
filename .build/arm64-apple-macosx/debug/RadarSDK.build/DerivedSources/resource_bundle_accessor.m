#import <Foundation/Foundation.h>

NSBundle* RadarSDK_SWIFTPM_MODULE_BUNDLE() {
    NSURL *bundleURL = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"RadarSDK_RadarSDK.bundle"];

    NSBundle *preferredBundle = [NSBundle bundleWithURL:bundleURL];
    if (preferredBundle == nil) {
      return [NSBundle bundleWithPath:@"/Users/shicheng.lu/Documents/radar/radar-sdk-ios/.build/arm64-apple-macosx/debug/RadarSDK_RadarSDK.bundle"];
    }

    return preferredBundle;
}