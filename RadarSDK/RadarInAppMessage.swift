//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import SwiftUI

@objc @objcMembers
public final class RadarInAppMessage : NSObject, Sendable {
    public struct Text: Sendable {
        public let text: String
        public let color: UIColor
    }

    public struct Button: Sendable {
        public let text: String
        public let color: UIColor
        public let backgroundColor: UIColor
        public let deepLink: String?
    }

    public struct Image: Sendable {
        public let name: String
        public let url: String
    }

    public let title: Text
    public let body: Text
    public let button: Button?
    public let image: Image?
    public let metadata: [String: Sendable]

    init(title: Text, body: Text, button: Button?, image: Image?, metadata: [String: Sendable]) {
        self.title = title
        self.body = body
        self.button = button
        self.image = image
        self.metadata = metadata
    }

    public static func fromDictionary(_ dict: [String: Any]) -> RadarInAppMessage? {
        // required fields
        guard let title = Text.fromDictionary(dict: dict["title"]),
              let body = Text.fromDictionary(dict: dict["body"]) else {
            return nil
        }
        // optional fields
        let button = Button.fromDictionary(dict: dict["button"])
        let image = Image.fromDictionary(dict: dict["image"])
        let metadata = dict["metadata"] as? [String: Sendable] ?? [:]

        return RadarInAppMessage(
            title: title, body: body, button: button, image: image, metadata: metadata
        )
    }

    public static func fromArray(_ array: Any) -> [RadarInAppMessage] {
        guard let array = array as? [[String: Any]] else {
            return [];
        }
        return array.compactMap(RadarInAppMessage.fromDictionary);
    }
}

// constructors
func uiColorFromString(_ string: String?) -> UIColor? {
    if let colorString = string,
       let colorValue = Int(colorString.dropFirst(), radix: 16) {
        return UIColor(
            red: CGFloat((colorValue >> 16) & 0xff) / 0xff,
            green: CGFloat((colorValue >> 8) & 0xff) / 0xff,
            blue: CGFloat((colorValue >> 0) & 0xff) / 0xff,
            alpha: 1.0)
    }
    return nil
}

extension RadarInAppMessage.Text {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage.Text? {
        guard let dict = dict as? Dictionary<String, String>,
              let text = dict["text"],
              let color = uiColorFromString(dict["color"]) else {
            return nil
        }

        return RadarInAppMessage.Text(
            text: text,
            color: color
        )
    }
}

extension RadarInAppMessage.Button {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage.Button? {
        guard let dict = dict as? Dictionary<String, String?>,
              let text = dict["text"] ?? nil,
              let color = uiColorFromString(dict["color"] ?? nil),
              let backgroundColor = uiColorFromString(dict["backgroundColor"] ?? nil) else {
            return nil
        }
        let deepLink = dict["deepLink"] ?? nil

        return RadarInAppMessage.Button(
            text: text, color: color, backgroundColor: backgroundColor, deepLink: deepLink
        )
    }
}

extension RadarInAppMessage.Image {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage.Image? {
        guard let dict = dict as? Dictionary<String, String>,
              let name = dict["name"],
              let url = dict["url"] else {
            return nil
        }

        return RadarInAppMessage.Image(
            name: name, url: url
        )
    }
}
