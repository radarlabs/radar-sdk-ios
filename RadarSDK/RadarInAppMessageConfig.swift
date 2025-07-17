//
//  RadarInAppMessageConfig.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 7/14/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc
public class RadarInAppMessageConfig : NSObject, Codable {

    public class Text {
        var text: String
        var font: String
        var size: CGFloat
        
        init(text: String, font: String, size: CGFloat, colorHex: String) {
            self.text = text
            self.font = font
            self.size = size
            
            var colorValue = Int(colorHex, radix: 16)
            
        }
    }
    
    var type: String = ""
    var title: String = ""
    var body: String = ""
    var primaryActionText: String = ""
    var secondaryActionText: String?
    var font: String = ""
    
        
    public static func fromDictionary(dict: Dictionary<String, Any>) -> RadarInAppMessageConfig {
        let config = RadarInAppMessageConfig()
        config.type = dict["type"] as! String
        config.title = dict["title"] as! String
        config.body = dict["body"] as! String
        config.font = dict["font"] as! String
        return config
    }
}
