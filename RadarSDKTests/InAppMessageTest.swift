//
//  InAppMessageTest.swift
//  RadarSDKTests
//
//  Created by ShiCheng Lu on 8/6/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable
import RadarSDK
import SwiftUI

class MockRadarInAppMessageDelegate : NSObject, RadarInAppMessageProtocol {
    var onNewInAppMessageCounter = 0;
    var onNewInAppMessageReturn = RadarInAppMessageOperation.ignore;
    func onNewInAppMessage(_ message: RadarSDK.RadarInAppMessage) -> RadarInAppMessageOperation {
        onNewInAppMessageCounter += 1;
        return onNewInAppMessageReturn;
    }
    
    var onInAppMessageDismissedCounter = 0;
    func onInAppMessageDismissed(_ message: RadarSDK.RadarInAppMessage) {
        onInAppMessageDismissedCounter += 1;
    }
    
    var onInAppMessageButtonClickedCounter = 0;
    func onInAppMessageButtonClicked(_ message: RadarSDK.RadarInAppMessage) {
        onInAppMessageButtonClickedCounter += 1;
    }
    
    var createInAppMessageViewCounter = 0;
    var createInAppMessageViewReturnValue: UIViewController = UIViewController();
    func createInAppMessageView(_ message: RadarSDK.RadarInAppMessage) async -> UIViewController {
        createInAppMessageViewCounter += 1;
        return createInAppMessageViewReturnValue
    }
}


@Suite
struct InAppMessageTest {
    
    let message = RadarInAppMessage.fromDictionary([
        "title": [
            "text": "This is the title",
            "color": "#ff0000"
        ],
        "body": [
            "text": "This is a demo message.",
            "color": "#00ff00"
        ],
        "button": [
            "text": "Buy it",
            "color": "#0000ff",
            "backgroundColor": "#EB0083",
        ],
        "image": [
            "url": "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg",
            "name": "image.jpeg"
        ]
    ])
    
    @Test("In App message construction")
    @available(iOS 13.0, *)
    func InAppMessageTestConstruction() async throws {
        #expect(message != nil)
        #expect(message!.title.text == "This is the title")
        #expect(message!.title.color == UIColor(red: 1, green: 0, blue: 0, alpha: 1))
        #expect(message!.body.text == "This is a demo message.")
        #expect(message!.body.color == UIColor(red: 0, green: 1, blue: 0, alpha: 1))
        #expect(message!.button?.text == "Buy it")
        #expect(message!.button?.color == UIColor(red: 0, green: 0, blue: 1, alpha: 1))
        #expect(message!.button?.backgroundColor == UIColor(red: 0xeb/255, green: 0x00/255, blue: 0x83/255, alpha: 1))
        #expect(message!.image?.name == "image.jpeg")
        #expect(message!.image?.url == "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg")
    }
//    
    @Test("In App message received calls create view")
    @MainActor
    @available(iOS 14.0, *)
    func InAppMessageTestCreateView() async throws {
        let mockDelegate = MockRadarInAppMessageDelegate()
        RadarInAppMessageManager.setDelegate(mockDelegate)
        RadarInAppMessageManager.getKeyWindow = {
            return UIWindow()
        }
        mockDelegate.onNewInAppMessageReturn = .show
        
        RadarInAppMessageManager.onInAppMessageReceived(messages: [message!])
        
        try await Task.sleep(nanoseconds: 1_000_000)
        
        #expect(mockDelegate.onNewInAppMessageCounter == 1)
        #expect(mockDelegate.createInAppMessageViewCounter == 1)
    }
    
    @Test
    @MainActor
    @available(iOS 13.0, *)
    func InAppMessageTestNotShow() async throws {
        let mockDelegate = MockRadarInAppMessageDelegate()
        RadarInAppMessageManager.setDelegate(mockDelegate)
        RadarInAppMessageManager.getKeyWindow = {
            return UIWindow()
        }
        
        mockDelegate.onNewInAppMessageReturn = .ignore
        
        RadarInAppMessageManager.onInAppMessageReceived(messages: [message!])
        
        #expect(mockDelegate.onNewInAppMessageCounter == 1)
        #expect(mockDelegate.createInAppMessageViewCounter == 0)
    }
    
    @Test
    @MainActor
    @available(iOS 13.0, *)
    func InAppMessageViewAlreadyExist() async throws {
        RadarInAppMessageManager.getKeyWindow = {
            return UIWindow()
        }
        
    }
}

