//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/22/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@objc
public class RadarInAppMessage : NSObject {
    
    public class Text {
        var text: String = ""
        var size: CGFloat?
        var color: UIColor?
        var font: String?
        
        func fromDictionary(dict: Any?) -> Text? {
            guard let dict = dict as? Dictionary<String, String>,
                      dict["text"] != nil else {
                return nil
            }
            
            self.text = dict["text"]!
            
            if let colorString = dict["color"],
               let colorValue = Int(colorString, radix: 16) {
                self.color = UIColor(
                    red: CGFloat((colorValue >> 24) & 0xff) / 0xff,
                    green: CGFloat((colorValue >> 16) & 0xff) / 0xff,
                    blue: CGFloat((colorValue >> 8) & 0xff) / 0xff,
                    alpha: CGFloat((colorValue >> 0) & 0xff) / 0xff)
            }
            
            return self
        }
    }
    
    public class Button : Text {
        public var url: String?
        public var backgroundColor: UIColor?
        
        override func fromDictionary(dict: Any?) -> Button? {
            guard let dict = dict as? Dictionary<String, String>,
                  super.fromDictionary(dict: dict) != nil else {
                return nil
            }
            
            self.url = dict["url"]
            
            if let colorString = dict["backgroundColor"],
               let colorValue = Int(colorString, radix: 16) {
                self.backgroundColor = UIColor(
                    red: CGFloat((colorValue >> 24) & 0xff) / 0xff,
                    green: CGFloat((colorValue >> 16) & 0xff) / 0xff,
                    blue: CGFloat((colorValue >> 8) & 0xff) / 0xff,
                    alpha: CGFloat((colorValue >> 0) & 0xff) / 0xff)
            }
            return self
        }
    }
    
    var type: String = ""
    
    public var title: Text?
    public var body: Text?
    public var action: Button?
    
    var receivedLive: Bool = true
    var imageURL: String = ""

    @objc public static func fromDictionary(dict: Dictionary<String, Any>) -> RadarInAppMessage {
        let message = RadarInAppMessage()
        message.type = dict["type"] as! String
        
        message.title = Text().fromDictionary(dict: dict["title"])
        message.body = Text().fromDictionary(dict: dict["body"])
        message.action = Button().fromDictionary(dict: dict["action"])
        
        message.imageURL = dict["imageURL"] as! String
        return message
    }
}
