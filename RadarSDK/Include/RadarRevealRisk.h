//
//  RadarRevealRisk.h
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/10/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

@interface RadarRevealRiskRisk : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull level;
@property (nonatomic, readonly, copy) NSArray<NSString *> * _Nonnull reasons;
@end

@interface RadarRevealRiskNetworkAsn : NSObject
@property (nonatomic, readonly, copy) NSString * _Nullable asn;
@property (nonatomic, readonly, copy) NSString * _Nullable country;
@property (nonatomic, readonly, copy) NSString * _Nullable domain;
@property (nonatomic, readonly, copy) NSString * _Nullable name;
@property (nonatomic, readonly, copy) NSString * _Nullable network;
@property (nonatomic, readonly, copy) NSString * _Nullable type;
@end

@interface RadarRevealRiskNetworkIpAddressGeometry : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull type;
@property (nonatomic, readonly, copy) NSArray<NSNumber *> * _Nonnull coordinates;
@end

@interface RadarRevealRiskNetworkIpAddress : NSObject
@property (nonatomic, readonly, copy) NSString * _Nullable countryCode;
@property (nonatomic, readonly, copy) NSString * _Nullable country;
@property (nonatomic, readonly, copy) NSString * _Nullable countryFlag;
@property (nonatomic, readonly, copy) NSString * _Nullable state;
@property (nonatomic, readonly, copy) NSString * _Nullable city;
@property (nonatomic, readonly, copy) NSString * _Nullable postalCode;
@property (nonatomic, readonly, strong) NSNumber * _Nullable latitude;
@property (nonatomic, readonly, strong) NSNumber * _Nullable longitude;
@property (nonatomic, readonly, copy) NSString * _Nullable connectionType;
@property (nonatomic, readonly, copy) NSString * _Nullable stateCode;
@property (nonatomic, readonly, copy) NSString * _Nullable stateConfidence;
@property (nonatomic, readonly, copy) NSString * _Nullable countryConfidence;
@property (nonatomic, readonly, copy) NSString * _Nullable dma;
@property (nonatomic, readonly, copy) NSString * _Nullable dmaCode;
@property (nonatomic, readonly) BOOL stateAllowed;
@property (nonatomic, readonly) BOOL countryAllowed;
@property (nonatomic, readonly, copy) NSString * _Nullable layer;
@property (nonatomic, readonly, strong) RadarRevealRiskNetworkIpAddressGeometry * _Nullable geometry;
@end

@interface RadarRevealRiskNetworkPrivacy : NSObject
@property (nonatomic, readonly) BOOL hosting;
@property (nonatomic, readonly) BOOL proxy;
@property (nonatomic, readonly) BOOL relay;
@property (nonatomic, readonly, copy) NSString * _Nullable service;
@property (nonatomic, readonly) BOOL tor;
@property (nonatomic, readonly) BOOL vpn;
@property (nonatomic, readonly) BOOL residentialProxy;
@end

@interface RadarRevealRiskNetwork : NSObject
@property (nonatomic, readonly, strong) RadarRevealRiskNetworkIpAddress * _Nullable ipAddress;
@property (nonatomic, readonly, strong) RadarRevealRiskNetworkPrivacy * _Nullable privacy;
@property (nonatomic, readonly, strong) RadarRevealRiskNetworkAsn * _Nullable asn;
@end

@interface RadarRevealRiskDevice : NSObject
@property (nonatomic, readonly, copy) NSString * _Nullable deviceId;
@property (nonatomic, readonly, copy) NSString * _Nullable deviceType;
@property (nonatomic, readonly, copy) NSString * _Nullable deviceMake;
@property (nonatomic, readonly, copy) NSString * _Nullable deviceModel;
@property (nonatomic, readonly, copy) NSString * _Nullable deviceOSName;
@property (nonatomic, readonly, copy) NSString * _Nullable deviceOSVersion;
@property (nonatomic, readonly, copy) NSString * _Nullable sdkVersion;
@property (nonatomic, readonly, copy) NSString * _Nullable xPlatformType;
@property (nonatomic, readonly, copy) NSString * _Nullable installId;
@property (nonatomic, readonly, copy) NSString * _Nullable appId;
@property (nonatomic, readonly, copy) NSString * _Nullable appName;
@property (nonatomic, readonly, copy) NSString * _Nullable appVersion;
@property (nonatomic, readonly, copy) NSString * _Nullable appBuild;
@end

@interface RadarRevealRisk : NSObject
@property (nonatomic, readonly, copy) NSString * _Nonnull _id;
@property (nonatomic, readonly, copy) NSString * _Nullable token;
@property (nonatomic, readonly, copy) NSDate * _Nullable expiresAt;
@property (nonatomic, readonly, strong) NSNumber * _Nullable expiresIn;
@property (nonatomic, readonly, strong) RadarRevealRiskRisk * _Nonnull risk;
@property (nonatomic, readonly, strong) RadarRevealRiskNetwork * _Nonnull network;
@property (nonatomic, readonly, strong) RadarRevealRiskDevice * _Nonnull device;

-(NSDictionary*_Nonnull) dictionaryValue;
@end
