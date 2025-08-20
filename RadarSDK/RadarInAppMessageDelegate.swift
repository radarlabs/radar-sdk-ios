//
//  RadarInAppMessageDelegate.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
@objc(RadarInAppMessageDelegate_Swift)
@objcMembers
@MainActor
open class RadarInAppMessageDelegate : NSObject, RadarInAppMessageProtocol {

    @available(iOS 13.0, *)
    public static func loadImage(_ url: String) async -> UIImage? {
        if (url.isEmpty) {
            return nil
        }
        do {
            let data = try await RadarAPIClient.shared.getAsset(url: url)
            return UIImage(data: data)
        } catch {
            RadarLogger.shared.debug("API request error")
            // error in API request or converting to image
            return nil
        }
    }
    
    /**
     returns the view controller for the message to show, can be overwritten to display a custom view
     */
    open func createInAppMessageView(_ message: RadarInAppMessage, onDismiss: @escaping () -> Void, onInAppMessageClicked: @escaping () -> Void, completionHandler: @escaping (UIViewController) -> Void) {
        Task {
            var image: UIImage? = nil
            if let imageUrl = message.image?.url {
                image = await RadarInAppMessageDelegate.loadImage(imageUrl)
            }
            let viewController = UIHostingController(rootView: RadarIAMView(message: message, image: image, onDismiss: onDismiss, onInAppMessageClicked: onInAppMessageClicked))
            completionHandler(viewController)
        }
    }

    open func onInAppMessageButtonClicked(_ message: RadarInAppMessage) {
        if let urlString = message.button?.url,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        RadarInAppMessageManager.shared.dismissInAppMessage()
    }

    open func onInAppMessageDismissed(_ message: RadarInAppMessage) {
        RadarInAppMessageManager.shared.dismissInAppMessage()
    }

    open func onNewInAppMessage(_ message: RadarInAppMessage) -> RadarInAppMessageOperation {
        return .show
    }
}
