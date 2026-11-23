//
//  SnapshotCanonicalJSON.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Writes the canonical JSON text used by the serialization snapshots.
///
/// The Android SDK's snapshot tests write the same format, so the two platforms' snapshots can be
/// compared as text. The rules:
/// - Object keys sorted by Unicode code point. Two-space indent, `"key": value`, one array element
///   per line, `{}` and `[]` when empty, and a trailing newline.
/// - Strings escape only `"`, `\` and U+0000–U+001F (`\n`, `\t`, `\r`, `\b`, `\f`, otherwise
///   `\u00xx` in lowercase hex). `/` and non-ASCII characters are written as UTF-8.
/// - `NSNull` is `null`.
/// - `NSNumber` is encoded by its type, the way Flutter's standard message codec reads it:
///   - A `CFBoolean` (`@YES`, Swift `Bool`) is `true` or `false`.
///   - An integer `objCType` (`c s i l q C S I L Q`) is written as an integer.
///   - A floating `objCType` (`d f`) is written as a double, in the shortest form that round-trips,
///     always with a decimal point or an exponent so `42.0` stays `42.0`. A `float` is widened to
///     `double` first, as the codec does. The layout follows Java's `Double.toString`: plain
///     decimal when 1e-3 <= |x| < 1e7, otherwise `d.ddde±n` with a lowercase `e`, no `+` and no
///     leading zeros in the exponent (for example `1.0e-7`, `1.2345678e7`). NaN and infinity fail.
/// - Any other type fails, naming the type and its key path. That includes `NSDate`: neither
///   bridge can carry one (Flutter's standard codec throws on it, and React Native's conversion
///   drops it), so a serializer that returns one needs a decision rather than a guess here.
enum SnapshotCanonicalJSON {
    struct UnsupportedValue: Error, CustomStringConvertible {
        let path: String
        let reason: String

        var description: String { "\(path): \(reason)" }
    }

    /// Returns the canonical JSON text for `value`, ending with a newline.
    static func string(from value: Any) throws -> String {
        var output = ""
        try write(value, path: "$", indent: 0, to: &output)
        output += "\n"
        return output
    }

    private static func write(_ value: Any, path: String, indent: Int, to output: inout String) throws {
        // Bridge Swift values to the Objective-C objects the wrappers' bridges receive.
        let object = value as AnyObject

        switch object {
        case is NSNull:
            output += "null"
        case let string as NSString:
            output += quoted(string as String)
        case let number as NSNumber:
            output += try encode(number, path: path)
        case let dictionary as NSDictionary:
            try write(dictionary, path: path, indent: indent, to: &output)
        case let array as NSArray:
            try write(array, path: path, indent: indent, to: &output)
        case is NSDate:
            throw UnsupportedValue(path: path, reason: "no snapshot encoding rule for NSDate (\(object)); the bridges can't carry it")
        default:
            throw UnsupportedValue(path: path, reason: "no snapshot encoding rule for \(type(of: value)) (\(String(describing: value)))")
        }
    }

    private static func write(_ dictionary: NSDictionary, path: String, indent: Int, to output: inout String) throws {
        guard dictionary.count > 0 else {
            output += "{}"
            return
        }
        var entries: [(key: String, value: Any)] = []
        for (key, value) in dictionary {
            guard let key = key as? String else {
                throw UnsupportedValue(path: path, reason: "non-string key \(type(of: key)) (\(key))")
            }
            entries.append((key, value))
        }
        entries.sort { $0.key.unicodeScalars.map(\.value).lexicographicallyPrecedes($1.key.unicodeScalars.map(\.value)) }

        output += "{\n"
        for (index, entry) in entries.enumerated() {
            output += padding(indent + 1) + quoted(entry.key) + ": "
            try write(entry.value, path: "\(path).\(entry.key)", indent: indent + 1, to: &output)
            output += index == entries.count - 1 ? "\n" : ",\n"
        }
        output += padding(indent) + "}"
    }

    private static func write(_ array: NSArray, path: String, indent: Int, to output: inout String) throws {
        guard array.count > 0 else {
            output += "[]"
            return
        }
        output += "[\n"
        for (index, element) in array.enumerated() {
            output += padding(indent + 1)
            try write(element, path: "\(path)[\(index)]", indent: indent + 1, to: &output)
            output += index == array.count - 1 ? "\n" : ",\n"
        }
        output += padding(indent) + "]"
    }

    private static func padding(_ indent: Int) -> String {
        String(repeating: "  ", count: indent)
    }

    // MARK: - Numbers

    private static func encode(_ number: NSNumber, path: String) throws -> String {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return number.boolValue ? "true" : "false"
        }
        let objCType = String(cString: number.objCType)
        switch objCType {
        case "c", "s", "i", "l", "q":
            return String(number.int64Value)
        case "C", "S", "I", "L", "Q":
            return String(number.uint64Value)
        case "d", "f":
            return try encode(number.doubleValue, path: path)
        default:
            throw UnsupportedValue(path: path, reason: "no snapshot encoding rule for NSNumber with objCType \"\(objCType)\" (\(number))")
        }
    }

    /// Formats a double like Java's `Double.toString`, using Swift's shortest round-trip digits.
    static func encode(_ double: Double, path: String = "$") throws -> String {
        guard double.isFinite else {
            throw UnsupportedValue(path: path, reason: "\(double) isn't valid JSON")
        }
        if double == 0 {
            return double.sign == .minus ? "-0.0" : "0.0"
        }

        let magnitude = abs(double)
        let sign = double < 0 ? "-" : ""
        // Swift's description is the shortest string that round-trips. Take its digits and
        // decimal exponent, then lay them out the Java way.
        let (digits, exponent) = decimalDigits(of: magnitude.description)
        if magnitude >= 1e-3 && magnitude < 1e7 {
            // `digits` is d1 d2 d3 ... with the value d1.d2d3... × 10^exponent.
            if exponent >= 0 {
                let integerCount = exponent + 1
                let paddedDigits = digits + String(repeating: "0", count: max(0, integerCount - digits.count))
                let integerPart = String(paddedDigits.prefix(integerCount))
                let fractionPart = String(paddedDigits.dropFirst(integerCount))
                return sign + integerPart + "." + (fractionPart.isEmpty ? "0" : fractionPart)
            } else {
                return sign + "0." + String(repeating: "0", count: -exponent - 1) + digits
            }
        }
        let rest = String(digits.dropFirst())
        return sign + String(digits.prefix(1)) + "." + (rest.isEmpty ? "0" : rest) + "e" + String(exponent)
    }

    /// Splits a Swift floating-point description such as `"40.7039"`, `"1e-07"` or `"1.5e+16"`
    /// into significant digits (no leading or trailing zeros) and the decimal exponent of the
    /// first digit.
    private static func decimalDigits(of description: String) -> (digits: String, exponent: Int) {
        let parts = description.lowercased().split(separator: "e", maxSplits: 1)
        let mantissa = parts[0]
        let explicitExponent = parts.count > 1 ? Int(parts[1]) ?? 0 : 0

        let mantissaParts = mantissa.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(mantissaParts[0])
        let fractionPart = mantissaParts.count > 1 ? String(mantissaParts[1]) : ""

        var digits = Array(integerPart + fractionPart)
        var pointPosition = integerPart.count
        while digits.first == "0" {
            digits.removeFirst()
            pointPosition -= 1
        }
        while digits.last == "0" {
            digits.removeLast()
        }
        return (String(digits), pointPosition - 1 + explicitExponent)
    }

    // MARK: - Strings

    private static func quoted(_ string: String) -> String {
        var output = "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"":
                output += "\\\""
            case "\\":
                output += "\\\\"
            case "\n":
                output += "\\n"
            case "\t":
                output += "\\t"
            case "\r":
                output += "\\r"
            case "\u{08}":
                output += "\\b"
            case "\u{0C}":
                output += "\\f"
            default:
                if scalar.value < 0x20 {
                    output += String(format: "\\u%04x", scalar.value)
                } else {
                    output.unicodeScalars.append(scalar)
                }
            }
        }
        return output + "\""
    }
}
