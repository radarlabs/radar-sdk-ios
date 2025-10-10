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
- (nonnull instancetype)init;
@end

@interface RadarAPIClient_PostConfigResponse : NSObject
@property (nonatomic, readonly) RadarStatus status;
@property (nonatomic, readonly, strong) RadarTrackingOptions * _Nullable remoteTrackingOptions;
@property (nonatomic, readonly, strong) RadarSdkConfiguration * _Nullable remoteSdkConfiguration;
@property (nonatomic, readonly, strong) RadarConfig * _Nullable verificationSettings;
@property (nonatomic, readonly, strong) RadarAPIClient_OfflineData * _Nullable offlineData;
- (nonnull instancetype)init;
@end

@interface RadarAPIClientSwift : NSObject
@property (nonatomic, class, readonly, strong) RadarAPIClientSwift * _Nonnull shared;
+ (RadarAPIClientSwift * _Nonnull)shared;
- (void)getAssetWithUrl:(NSString * _Nonnull)url completionHandler:(void (^ _Nonnull)(NSData * _Nullable, NSError * _Nullable))completionHandler;
- (void)postConfigWithUsage:(NSString * _Nonnull)usage completionHandler:(void (^ _Nonnull)(RadarAPIClient_PostConfigResponse * _Nonnull))completionHandler;
- (nonnull instancetype)init;
@end
