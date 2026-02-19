//
//  InAppMessageTest.swift
//  RadarSDKTests
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing
@testable
import RadarSDK
import SwiftUI

@available(iOS 13.0, *)
@MainActor
class MockRadarInAppMessageDelegate : NSObject, RadarInAppMessageProtocol {
    weak var manager: RadarInAppMessageManager?
    init(manager: RadarInAppMessageManager) {
        self.manager = manager
    }

    var onNewInAppMessageCounter = 0
    var showInAppMessage = false
    func onNewInAppMessage(_ message: RadarSDK.RadarInAppMessage) {
        onNewInAppMessageCounter += 1
        if (showInAppMessage) {
            Task {
                await manager?.showInAppMessage(message)
            }
        }
    }

    var onInAppMessageDismissedCounter = 0
    func onInAppMessageDismissed(_ message: RadarSDK.RadarInAppMessage) {
        onInAppMessageDismissedCounter += 1
        manager?.dismissInAppMessage()
    }

    var onInAppMessageButtonClickedCounter = 0
    func onInAppMessageButtonClicked(_ message: RadarSDK.RadarInAppMessage) {
        onInAppMessageButtonClickedCounter += 1
        manager?.dismissInAppMessage()
    }

    var createInAppMessageViewCounter = 0
    var createInAppMessageViewReturnValue: UIViewController = UIViewController()
    var viewOnDismiss: (() -> Void)?
    var viewOnInAppMessageClicked: (() -> Void)?
    func createInAppMessageView(_ message: RadarSDK.RadarInAppMessage,
                                onDismiss: @escaping () -> Void,
                                onInAppMessageClicked: @escaping () -> Void) async -> UIViewController {
        createInAppMessageViewCounter += 1
        viewOnDismiss = onDismiss
        viewOnInAppMessageClicked = onInAppMessageClicked
        return createInAppMessageViewReturnValue
    }
}

class MockWindow : UIWindow {
    var addSubviewCounter = 0
    var continuation: CheckedContinuation<Void, Never>?
    override func addSubview(_ view: UIView) {
        addSubviewCounter += 1
        continuation?.resume()
        continuation = nil
    }
    
    func waitForSubviewAddition() async {
        if (addSubviewCounter > 0) {
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            // Store the continuation and wait for `addSubview(_:)` to call `resume()`
            self.continuation = continuation
        }
    }
}

@Suite
actor InAppMessageTest {
    @MainActor
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
        ],
        "metadata": [
            "campaignId": "1234"
        ]
    ])

    @Test("In app message construction")
    @MainActor
    func InAppMessageTestConstruction() throws {
        let message = message as? RadarInAppMessage_Swift
        
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
        #expect(message!.metadata["campaignId"] as? String == "1234")
    }
    
    @Test("In app message to dictionary")
    @MainActor
    func InAppMessageTestToDictionary() throws {
        let dict = message?.toDictionary()
        #expect(dict != nil)
        
        let title = dict!["title"] as? [String: String]
        #expect(title != nil)
        #expect(title!["text"] == "This is the title")
        #expect(title!["color"] == "#ff0000")
        
        let body = dict!["body"] as? [String: String]
        #expect(body != nil)
        #expect(body!["text"] == "This is a demo message.")
        #expect(body!["color"] == "#00ff00")
        
        let button = dict!["button"] as? [String: String]
        #expect(button != nil)
        #expect(button!["text"] == "Buy it")
        #expect(button!["color"] == "#0000ff")
        #expect(button!["backgroundColor"] == "#eb0083")
        
        let image = dict!["image"] as? [String: String]
        #expect(image != nil)
        #expect(image!["url"] == "https://images.pexels.com/photos/949587/pexels-photo-949587.jpeg")
        #expect(image!["name"] == "image.jpeg")
        
        let metadata = dict!["metadata"] as? [String: Any]
        #expect(metadata != nil)
        #expect(metadata!["campaignId"] as? String == "1234")
    }
    

    @Test("In app message received calls create view")
    @MainActor
    @available(iOS 14.0, *)
    func InAppMessageTestCreateView() async throws {
        let manager = RadarInAppMessageManager()
        let mockDelegate = MockRadarInAppMessageDelegate(manager: manager)
        manager.setDelegate(mockDelegate)
        let mockWindow = MockWindow()
        manager.getKeyWindow = { return mockWindow }
        mockDelegate.showInAppMessage = true

        manager.onInAppMessageReceived(messages: [message!])

        await mockWindow.waitForSubviewAddition()

        #expect(mockDelegate.onNewInAppMessageCounter == 1)
        #expect(mockDelegate.createInAppMessageViewCounter == 1)

        // pretend to click on the button
        mockDelegate.viewOnInAppMessageClicked?()

        #expect(mockDelegate.onInAppMessageButtonClickedCounter == 1)

        #expect(manager.view == nil)

    }

    @Test("if there is already an IAM, don't show another")
    @MainActor
    @available(iOS 13.0, *)
    func InAppMessageViewAlreadyExist() async throws {
        let manager = RadarInAppMessageManager()
        let mockDelegate = MockRadarInAppMessageDelegate(manager: manager)
        manager.setDelegate(mockDelegate)
        let mockWindow = MockWindow()
        manager.getKeyWindow = { return mockWindow }

        mockDelegate.showInAppMessage = true

        manager.onInAppMessageReceived(messages: [message!])
        manager.onInAppMessageReceived(messages: [message!])

        await mockWindow.waitForSubviewAddition()

        #expect(mockDelegate.onNewInAppMessageCounter == 2)
        // 2 views could be created since creating the view is async
        #expect(mockDelegate.createInAppMessageViewCounter == 1 || mockDelegate.createInAppMessageViewCounter == 2)
        // but only 1 should be shown
        #expect(mockWindow.addSubviewCounter == 1)

        manager.onInAppMessageReceived(messages: [message!])

        #expect(mockDelegate.onNewInAppMessageCounter == 3)
        // after the view is shown, creating view also shouldn've be called
        #expect(mockDelegate.createInAppMessageViewCounter == 2)
        #expect(mockWindow.addSubviewCounter == 1)
    }
}
