//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@available(iOS 13.0, *)
@objc
public
class RadarInAppMessageManager: NSObject {
    @objc
    public static let shared = RadarInAppMessageManager()

    public var delegate: RadarInAppMessageProtocol = RadarInAppMessageDelegate()
    public var view: UIView?

    var messageShownTime: Date?
    var currentMessage: RadarInAppMessage?

    internal var getKeyWindow: () -> UIWindow? = {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }

    func logConversion(name: String) {
        guard let messageShownTime = messageShownTime,
              let message = currentMessage else {
            return
        }

        let messageClickTime = Date()
        let duration = messageClickTime.timeIntervalSince(messageShownTime)

        var metadata: [String: Any] = [:]
        metadata["duration"] = duration
        metadata["campaignId"] = message.metadata["radar:campaignId"] as? String
        metadata["campaignName"] = message.metadata["radar:campaignName"] as? String
        metadata["geofenceId"] = message.metadata["radar:geofenceId"] as? String

        // logConversion runs asynchronously
        Radar.logConversion(name: name, metadata: metadata, completionHandler: { status, event in
            if let event = event {
                RadarLogger.shared.info("Conversion name = \(event.conversionName ?? "-"): status = \(status); event = \(event.dictionaryValue())")
            } else {
                RadarLogger.shared.info("Conversion name = \(name): status = \(status); no event")
            }
        })
    }

    func dismissInAppMessage() {
        view?.removeFromSuperview()
        view = nil
        currentMessage = nil
    }

    @objc public func showInAppMessage(_ message: RadarInAppMessage) async {
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
            delegate.createInAppMessageView(message,
                                            onDismiss: {
                self.logConversion(name: "in_app_message_clicked")
                self.delegate.onInAppMessageDismissed(message)
            },
                                            onInAppMessageClicked: {
                self.logConversion(name: "in_app_message_dismissed")
                self.delegate.onInAppMessageButtonClicked(message)
            }) { result in
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
    }

    @objc public func onInAppMessageReceived(messages: [RadarInAppMessage]) {
        for message in messages {
            if (delegate.onNewInAppMessage(message) == RadarInAppMessageOperation.show) {
                Task {
                    await showInAppMessage(message)
                }
                break
            }
        }
    }

    @objc public func setDelegate(_ delegate: RadarInAppMessageProtocol) {
        self.delegate = delegate
    }
}
