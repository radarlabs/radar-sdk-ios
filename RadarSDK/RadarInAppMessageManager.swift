//
//  RadarInAppMessageManager.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
@objc
public class RadarInAppMessageManager: NSObject {
    @objc
    public static let shared = RadarInAppMessageManager()

    public var delegate: RadarInAppMessageProtocol = RadarInAppMessageDelegate()
    public var view: UIView?

    var messageShownTime: Date?
    var currentMessage: RadarInAppMessage_Swift?

    internal var getKeyWindow: () -> UIWindow? = {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }

    func logConversion(name: String, withDuration: Bool = true) {
        guard let messageShownTime = messageShownTime,
              let message = currentMessage else {
            return
        }

        var metadata: [String: Any] = [:]
        if (withDuration) {
            metadata["displayDuration"] = Date().timeIntervalSince(messageShownTime)
        }
        let campaignId = message.metadata["radar:campaignId"] as? String
        metadata["campaignId"] = campaignId
        metadata["campaignName"] = message.metadata["radar:campaignName"] as? String
        metadata["geofenceId"] = message.metadata["radar:geofenceId"] as? String

        // logConversion runs asynchronously
        RadarSwift.bridge?.logCampaignConversion(name: name, metadata: metadata, campaign: campaignId)
    }

    func dismissInAppMessage() {
        view?.removeFromSuperview()
        view = nil
        currentMessage = nil
    }

    @objc public func showInAppMessage(_ message: RadarInAppMessage) async {
        guard let message = message as? RadarInAppMessage_Swift else {
            return
        }
        // check before getting the view that there is no existing IAM shown
        if (view != nil) {
            RadarLogger.shared.debug("Existing in-app message view, new in-app message ignored")
            return
        }

        guard let keyWindow = getKeyWindow() else {
            // No key window
            RadarLogger.shared.debug("No key window found for app, new in-app message ignored")
            return
        }

        let viewController = await withCheckedContinuation { continuation in
            delegate.createInAppMessageView(
                message,
                onDismiss: {
                    self.logConversion(name: "user.dismissed_in_app_message")
                    self.dismissInAppMessage()
                    self.delegate.onInAppMessageDismissed(message)
                },
                onInAppMessageClicked: {
                    self.logConversion(name: "user.clicked_in_app_message")
                    self.dismissInAppMessage()
                    self.delegate.onInAppMessageButtonClicked(message)
                }
            ) { result in
                continuation.resume(returning: result)
            }
        }
        // check after getting the view asynchronously that there is no existing IAM shown
        if (view != nil) {
            RadarLogger.shared.debug("Existing in-app message view, new in-app message ignored")
            return
        }
        messageShownTime = Date()
        currentMessage = message
        view = viewController.view
        viewController.view.frame = UIScreen.main.bounds
        viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        keyWindow.addSubview(viewController.view)
        
        self.logConversion(name: "user.displayed_in_app_message", withDuration: false)
    }

    @objc public func onInAppMessageReceived(messages: [RadarInAppMessage]) {
        for message in messages {
            delegate.onNewInAppMessage(message)
        }
    }

    @objc public func setDelegate(_ delegate: RadarInAppMessageProtocol) {
        self.delegate = delegate
    }
}
