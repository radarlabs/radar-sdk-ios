//
//  RadarAPIClientSwift.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 10/8/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

@interface RadarAPIClient_OfflineData : NSObject
@property (nonatomic, readonly, copy) NSArray<RadarGeofence *> * _Nonnull newGeofences;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nonnull removeGeofences;
@property (nonatomic, readonly, strong) RadarTrackingOptions * _Nullable defaultTrackingOptions;
@property (nonatomic, readonly, strong) RadarTrackingOptions * _Nullable onTripTrackingOptions;
@property (nonatomic, readonly, strong) RadarTrackingOptions * _Nullable inGeofenceTrackingOptions;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nonnull inGeofenceTrackingTags;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@interface RadarAPIClient_PostConfigResponse : NSObject
@property (nonatomic, readonly) RadarStatus status;
@property (nonatomic, readonly, strong) RadarTrackingOptions * _Nullable remoteTrackingOptions;
@property (nonatomic, readonly, strong) RadarSdkConfiguration * _Nullable remoteSdkConfiguration;
@property (nonatomic, readonly, strong) RadarConfig * _Nullable verificationSettings;
@property (nonatomic, readonly, strong) RadarAPIClient_OfflineData * _Nullable offlineData;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@interface RadarAPIClientSwift : NSObject
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, readonly, strong) RadarAPIClientSwift * _Nonnull shared;)
+ (RadarAPIClientSwift * _Nonnull)shared SWIFT_WARN_UNUSED_RESULT;
- (void)getAssetWithUrl:(NSString * _Nonnull)url completionHandler:(void (^ _Nonnull)(NSData * _Nullable, NSError * _Nullable))completionHandler;
- (void)postConfigWithUsage:(NSString * _Nonnull)usage completionHandler:(void (^ _Nonnull)(RadarAPIClient_PostConfigResponse * _Nonnull))completionHandler;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end
