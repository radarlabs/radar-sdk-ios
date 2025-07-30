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
        public var text: String = ""
        public var size: CGFloat?
        public var color: UIColor?
        public var font: String?
        
        func fromDictionary(dict: Any?) -> Text? {
            guard let dict = dict as? Dictionary<String, String?>,
                      dict["text"] != nil else {
                return nil
            }
            
            self.text = dict["text"]!!
            
            if let colorString = dict["color"]!,
               let colorValue = Int(colorString.dropFirst(), radix: 16) {
                self.color = UIColor(
                    red: CGFloat((colorValue >> 16) & 0xff) / 0xff,
                    green: CGFloat((colorValue >> 8) & 0xff) / 0xff,
                    blue: CGFloat((colorValue >> 0) & 0xff) / 0xff,
                    alpha: 1.0)
            }
            
            return self
        }
    }
    
    public class Button : Text {
        public var url: String?
        public var backgroundColor: UIColor?
        
        override func fromDictionary(dict: Any?) -> Button? {
            guard let dict = dict as? Dictionary<String, String?>,
                  super.fromDictionary(dict: dict) != nil else {
                print("Failed to init button")
                return nil
            }
            
            self.url = dict["url"] as? String
            
            if let colorString = dict["backgroundColor"]!,
               let colorValue = Int(colorString.dropFirst(), radix: 16) {
                self.backgroundColor = UIColor(
                    red: CGFloat((colorValue >> 16) & 0xff) / 0xff,
                    green: CGFloat((colorValue >> 8) & 0xff) / 0xff,
                    blue: CGFloat((colorValue >> 0) & 0xff) / 0xff,
                    alpha: 1.0)
            }
            return self
        }
    }
    
    public class Image {
        public var url: String?
        public var name: String?
        
        func fromDictionary(dict: Any?) -> Image? {
            guard let dict = dict as? Dictionary<String, String> else {
                return nil
            }
            
            self.url = dict["url"]
            self.name = dict["name"]
            
            return self
        }
    }
    
    var type: String = ""
    
    public var title: Text?
    public var body: Text?
    public var button: Button?
    public var image: Image?
    
    var receivedLive: Bool = true

    @objc public static func fromDictionary(_ dict: [String: Any]) -> RadarInAppMessage {
        let message = RadarInAppMessage()
//        message.type = dict["type"] as! String
        
        message.title = Text().fromDictionary(dict: dict["title"])
        message.body = Text().fromDictionary(dict: dict["body"])
        message.button = Button().fromDictionary(dict: dict["button"])
        message.image = Image().fromDictionary(dict: dict["image"])
        
        return message
    }
    
    @objc public static func fromArray(_ array: Any) -> [RadarInAppMessage] {
        guard let array = array as? [[String: Any]] else {
            return [];
        }
        return array.map(RadarInAppMessage.fromDictionary);
    }
}
