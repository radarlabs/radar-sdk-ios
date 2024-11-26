//
//  RadarVerifyServer.h
//  RadarSDK
//
//  Created by Nick Patrick on 11/11/24.
//  Copyright © 2024 Radar Labs, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RadarVerifyServer: NSObject

<<<<<<< HEAD
+ (instancetype)sharedInstance;
- (void)startServerWithCertData:(NSData *)certData identityData:(NSData *)identityData;
=======
- (void)startServer;
>>>>>>> bd54448e (RadarVerifyServer)
- (void)stopServer;

@end
