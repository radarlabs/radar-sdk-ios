//
//  RadarIAMDelegate.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
func loadImage(_ url: String) async -> UIImage? {
    if (url.isEmpty) {
        return nil
    }
    
    let image: UIImage? = await withCheckedContinuation { continuation in
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        if (!url.starts(with: "http")) {
            let publishableKey = UserDefaults.standard.string(forKey: "radar-publishableKey")!
            let radarHost = UserDefaults.standard.string(forKey: "radar-host")!
            request.url = URL(string: "\(radarHost)/v1/assets/\(url)")
            request.addValue(publishableKey, forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard let data = data,
                  let image = UIImage(data: data) else {
                continuation.resume(returning: nil)
                return
            }
            continuation.resume(returning: image)
        }.resume()
    }
    return image
}

@available(iOS 13.0, *)
@objc(RadarInAppMessageDelegate_Swift)
@objcMembers
@MainActor
open class RadarInAppMessageDelegate : NSObject, RadarInAppMessageProtocol {
    /**
     returns the view controller for the message to show, can be overwritten to display a custom view
     */
    open func createInAppMessageView(_ message: RadarInAppMessage, completionHandler: @escaping (UIViewController) -> Void) {
        Task {
            var image: UIImage? = nil
            if let imageUrl = message.image?.url {
                image = await loadImage(imageUrl)
            }
            let viewController = UIHostingController(rootView: RadarIAMView(message: message, image: image))
            completionHandler(viewController)
        }
    }
    
    open func onInAppMessageButtonClicked(_ message: RadarInAppMessage) {
        if let url = message.button?.url {
            UIApplication.shared.open(URL(string: url)!)
        }
    }
    
    open func onInAppMessageDismissed(_ message: RadarInAppMessage) {
        RadarInAppMessageManager.dismissInAppMessage()
    }
    
    open func onNewInAppMessage(_ message: RadarInAppMessage) -> RadarInAppMessageOperation {
        return .show
    }
}


