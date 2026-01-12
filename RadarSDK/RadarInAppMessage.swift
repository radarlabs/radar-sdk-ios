//
//  RadarInAppMessage.swift
//  RadarSDK
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarInAppMessage_Swift) @objcMembers
public final class RadarInAppMessage_Swift : RadarInAppMessage {
    public struct Text: Sendable {
        public var text: String
        public var color: UIColor
    }

    public struct Button: Sendable {
        public var text: String
        public var color: UIColor
        public var backgroundColor: UIColor
        public var deepLink: String?
    }

    public struct Image: Sendable {
        public var name: String
        public var url: String
    }

    public var title: Text
    public var body: Text
    public var button: Button?
    public var image: Image?
    public var metadata: [String: Sendable]

    public init(title: Text, body: Text, button: Button?, image: Image?, metadata: [String: Sendable]) {
        self.title = title
        self.body = body
        self.button = button
        self.image = image
        self.metadata = metadata
    }

    public static override func fromDictionary(_ dict: [String: Any]) -> RadarInAppMessage? {
        // required fields
        guard let title = Text.fromDictionary(dict: dict["title"]),
              let body = Text.fromDictionary(dict: dict["body"]) else {
            return nil
        }
        // optional fields
        let button = Button.fromDictionary(dict: dict["button"])
        let image = Image.fromDictionary(dict: dict["image"])
        let metadata = dict["metadata"] as? [String: Sendable] ?? [:]

        return RadarInAppMessage_Swift(
            title: title, body: body, button: button, image: image, metadata: metadata
        )
    }

    public static override func fromArray(_ array: Any) -> [RadarInAppMessage] {
        guard let array = array as? [[String: Any]] else {
            return [];
        }
        return array.compactMap(RadarInAppMessage_Swift.fromDictionary);
    }
    
    public override func toDictionary() -> [String: Any] {
        var dict = [
            "title": title.toDictionary(),
            "body": body.toDictionary(),
            "metadata": metadata,
        ]
        if let button = button {
            dict["button"] = button.toDictionary()
        }
        if let image = image {
            dict["image"] = image.toDictionary()
        }
        return dict
    }
    
    public static func toDictionary(_ message: RadarInAppMessage) -> [String: Any] {
        guard let message = message as? RadarInAppMessage_Swift else {
            return [:]
        }
        return message.toDictionary()
    }
}

// constructors
func uiColorFromString(_ string: String?) -> UIColor? {
    guard var colorString = string else { return nil }
    if colorString.hasPrefix("#") {
        colorString.removeFirst()
    }
    guard let colorValue = Int(colorString, radix: 16) else { return nil }
    return UIColor(
        red: CGFloat((colorValue >> 16) & 0xff) / 0xff,
        green: CGFloat((colorValue >> 8) & 0xff) / 0xff,
        blue: CGFloat(colorValue & 0xff) / 0xff,
        alpha: 1.0
    )
}

func uiColorToString(_ color: UIColor) -> String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    let intR = Int(r * 0xff)
    let intG = Int(g * 0xff)
    let intB = Int(b * 0xff)
    return String(format: "#%02x%02x%02x", intR, intG, intB)
}

extension RadarInAppMessage_Swift.Text {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage_Swift.Text? {
        guard let dict = dict as? Dictionary<String, String>,
              let text = dict["text"],
              let color = uiColorFromString(dict["color"]) else {
            return nil
        }

        return RadarInAppMessage_Swift.Text(
            text: text,
            color: color
        )
    }
    
    func toDictionary() -> [String: String] {
        return [
            "text": text,
            "color": uiColorToString(color)
        ]
    }
}

extension RadarInAppMessage_Swift.Button {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage_Swift.Button? {
        guard let dict = dict as? Dictionary<String, String?>,
              let text = dict["text"] ?? nil,
              let color = uiColorFromString(dict["color"] ?? nil),
              let backgroundColor = uiColorFromString(dict["backgroundColor"] ?? nil) else {
            return nil
        }
        let deepLink = dict["deepLink"] ?? nil

        return RadarInAppMessage_Swift.Button(
            text: text, color: color, backgroundColor: backgroundColor, deepLink: deepLink
        )
    }
    
    func toDictionary() -> [String: String] {
        var dict = [
            "text": text,
            "color": uiColorToString(color),
            "backgroundColor": uiColorToString(backgroundColor)
        ]
        if deepLink != nil {
            dict["deepLink"] = deepLink
        }
        return dict
    }
}

extension RadarInAppMessage_Swift.Image {
    static func fromDictionary(dict: Any?) -> RadarInAppMessage_Swift.Image? {
        guard let dict = dict as? Dictionary<String, String>,
              let name = dict["name"],
              let url = dict["url"] else {
            return nil
        }

        return RadarInAppMessage_Swift.Image(
            name: name, url: url
        )
    }
    
    func toDictionary() -> [String: String] {
        return [
            "name": name,
            "url": url
        ]
    }
}

