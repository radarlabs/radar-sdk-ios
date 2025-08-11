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
    public static var delegate: RadarInAppMessageProtocol = RadarInAppMessageDelegate()
    public static var view: UIView?
    
    static var messageShownTime: Date?
    static var currentMessage: RadarInAppMessage?
    
    internal static var getKeyWindow: () -> UIWindow? = {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
    
    static func logConversion(name: String) {
        print("Log conversion: ---")
        guard let messageShownTime = messageShownTime,
              let message = currentMessage else {
            return
        }
        
        let messageClickTime = Date()
        let duration = messageClickTime.timeIntervalSince(messageShownTime)
        
        var metadata: [String: Any] = [:]
        metadata["display_duration"] = duration
        metadata["campaign_id"] = message.metadata["campaign_id"] as? String
        metadata["geofence_id"] = message.metadata["geofence_id"] as? String
        
        // logConversion runs asynchronously
        Radar.logConversion(name: name, metadata: metadata, completionHandler: { status, event in
            if let event = event {
                RadarLogger.shared.info("Conversion name = \(event.conversionName ?? "-"): status = \(status); event = \(event)")
            } else {
                RadarLogger.shared.info("Conversion name = \(name): status = \(status); no event")
            }
        })
    }
    
    static func dismissInAppMessage() {
        view?.removeFromSuperview()
        view = nil
        currentMessage = nil
    }
    
    @objc public static func showInAppMessage(_ message: RadarInAppMessage) async {
        // check before getting the view that there is no existing IAM shown
        if (view != nil) {
            return
        }
        
        guard let keyWindow = getKeyWindow() else {
            // No key window
            return
        }
        
        let viewController = await withCheckedContinuation { continuation in
            delegate.createInAppMessageView(message,
                                            onDismiss: { delegate.onInAppMessageDismissed(message) },
                                            onInAppMessageClicked: { delegate.onInAppMessageButtonClicked(message) }) { result in
                continuation.resume(returning: result)
            }
        }
        // check after getting the view asynchronously that there is no existing IAM shown
        if (view != nil) {
            return
        }
        messageShownTime = Date()
        currentMessage = message
        view = viewController.view
        viewController.view.frame = UIScreen.main.bounds
        viewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        keyWindow.addSubview(viewController.view)
    }
    
    @objc public static func onInAppMessageReceived(messages: [RadarInAppMessage]) {
        for message in messages {
            if (delegate.onNewInAppMessage(message) == RadarInAppMessageOperation.show) {
                Task {
                    await showInAppMessage(message)
                }
                break
            }
        }
    }
    
    @objc public static func setDelegate(_ delegate: RadarInAppMessageProtocol) {
        self.delegate = delegate
    }
}
