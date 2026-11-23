//
//  SerializationSnapshot.swift
//  RadarSDKTests
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import Testing

/// Compares serializer output with the snapshots in `RadarSDKTests/Resources/Serialized`.
///
/// Flutter, React Native and Capacitor pass `dictionaryValue` and `[Radar dictionaryForLocation:]`
/// output straight to app code, so a snapshot change means the wrappers may need a matching change.
///
/// To record snapshots instead of comparing, set `RADAR_RECORD_SNAPSHOTS=1` in the test process:
/// - Command line: `TEST_RUNNER_RADAR_RECORD_SNAPSHOTS=1 make test` (xcodebuild passes
///   `TEST_RUNNER_`-prefixed variables to the test process without the prefix).
/// - Xcode: add `RADAR_RECORD_SNAPSHOTS` = `1` under the scheme's Test action > Arguments >
///   Environment Variables, and don't commit the scheme change.
///
/// Recording writes into the source tree (found from this file's path, which works in the
/// simulator) and fails each test it records, so a run with the flag can't pass by accident. Run the
/// tests again without the flag to check the new snapshots. CI never sets the flag.
///
/// `Resources/Full` and `Resources/Serialized` are folder references in the Xcode project, so the
/// bundle keeps their directory structure and new files in them need no project change.
enum SerializationSnapshot {
    static let recordEnvironmentVariable = "RADAR_RECORD_SNAPSHOTS"
    private static let recordHint = "set RADAR_RECORD_SNAPSHOTS=1 (TEST_RUNNER_RADAR_RECORD_SNAPSHOTS=1 for xcodebuild)"

    static var isRecording: Bool {
        ProcessInfo.processInfo.environment[recordEnvironmentVariable] == "1"
    }

    private final class BundleToken {}

    private static let sourceResourcesDirectory = URL(fileURLWithPath: "\(#filePath)")
        .deletingLastPathComponent()
        .appendingPathComponent("Resources", isDirectory: true)

    private static var bundleResourcesDirectory: URL? {
        Bundle(for: BundleToken.self).resourceURL
    }

    /// Reads a JSON resource such as `Full/Address.json` from the test bundle.
    static func jsonObject(resource relativePath: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Any {
        let directory = try #require(bundleResourcesDirectory, sourceLocation: sourceLocation)
        let url = directory.appendingPathComponent(relativePath)
        let data = try #require(
            try? Data(contentsOf: url), "\(relativePath) isn't in the test bundle", sourceLocation: sourceLocation)
        return try JSONSerialization.jsonObject(with: data)
    }

    /// Canonicalizes `value` and compares it with `Serialized/<path>.json`, or writes that file when
    /// recording. `path` is `<fixture>/<model path>`, for example `geocode/addresses.0`, and must
    /// match the Android snapshot's path.
    static func assertMatches(_ value: Any, snapshot path: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let actual: String
        do {
            actual = try SnapshotCanonicalJSON.string(from: value)
        } catch {
            Issue.record("Can't write snapshot \(path): \(error)", sourceLocation: sourceLocation)
            return
        }

        let relativePath = "Serialized/\(path).json"
        if isRecording {
            let url = sourceResourcesDirectory.appendingPathComponent(relativePath)
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(actual.utf8).write(to: url, options: .atomic)
                Issue.record(
                    "Recorded \(url.path). Run the tests again without \(recordEnvironmentVariable) to compare.",
                    sourceLocation: sourceLocation)
            } catch {
                Issue.record("Can't record \(url.path): \(error)", sourceLocation: sourceLocation)
            }
            return
        }

        guard let url = bundleResourcesDirectory?.appendingPathComponent(relativePath),
            let data = try? Data(contentsOf: url),
            let expected = String(data: data, encoding: .utf8)
        else {
            Issue.record(
                "Snapshot \(relativePath) isn't in the test bundle. To record it, \(recordHint).\n\nActual:\n\(actual)",
                sourceLocation: sourceLocation)
            return
        }

        if expected != actual {
            Issue.record(
                """
                Serialized output doesn't match \(relativePath). If the change is intended, \(recordHint) to record it, \
                and check whether the wrappers need a matching change.
                (- snapshot, + actual)
                \(lineDiff(expected: expected, actual: actual))
                """,
                sourceLocation: sourceLocation)
        }
    }

    /// A line diff of two short texts: unchanged lines start with two spaces, removed lines with
    /// `- ` and added lines with `+ `.
    static func lineDiff(expected: String, actual: String) -> String {
        let old = expected.components(separatedBy: "\n")
        let new = actual.components(separatedBy: "\n")
        // Longest common subsequence table; snapshots are small, so O(n·m) is fine.
        var lengths = Array(repeating: Array(repeating: 0, count: new.count + 1), count: old.count + 1)
        for oldIndex in stride(from: old.count - 1, through: 0, by: -1) {
            for newIndex in stride(from: new.count - 1, through: 0, by: -1) {
                lengths[oldIndex][newIndex] = old[oldIndex] == new[newIndex] ? lengths[oldIndex + 1][newIndex + 1] + 1 : max(lengths[oldIndex + 1][newIndex], lengths[oldIndex][newIndex + 1])
            }
        }
        var lines: [String] = []
        var oldIndex = 0
        var newIndex = 0
        while oldIndex < old.count || newIndex < new.count {
            if oldIndex < old.count, newIndex < new.count, old[oldIndex] == new[newIndex] {
                lines.append("  " + old[oldIndex])
                oldIndex += 1
                newIndex += 1
            } else if oldIndex < old.count, newIndex == new.count || lengths[oldIndex + 1][newIndex] >= lengths[oldIndex][newIndex + 1] {
                lines.append("- " + old[oldIndex])
                oldIndex += 1
            } else {
                lines.append("+ " + new[newIndex])
                newIndex += 1
            }
        }
        return lines.joined(separator: "\n")
    }
}

/// Fails if any property of `instance`, or of a Radar model nested in it, is nil, or if any array
/// or dictionary is empty.
///
/// Unset optional fields are left out of `dictionaryValue`, so a full fixture must set every field
/// for its snapshot to show a field that's added later. This check keeps the fixture complete.
///
/// It reads Objective-C properties with the runtime (`class_copyPropertyList` and
/// `value(forKey:)`), which covers Objective-C models and Swift `@objcMembers` models, and
/// stored Swift properties that the runtime can't see with `Mirror`. It recurses into Radar models
/// and array elements, not into free-form dictionaries such as `metadata`.
///
/// It can't catch a property that's never nil, such as a primitive, an enum, a struct, or a
/// computed property with a default: a `0` offset or a `.none` confidence passes.
///
/// - Parameter allowedNull: properties that may be nil, as `ClassName.property`. Each entry needs a
///   comment saying why the fixture can't set it. An entry that matches nothing fails, so the list
///   can't go stale.
func assertFullyPopulated(_ instance: NSObject, allowedNull: Set<String> = [], sourceLocation: SourceLocation = #_sourceLocation) {
    var walker = FullyPopulatedWalker(allowedNull: allowedNull)
    walker.visit(instance, path: String(describing: type(of: instance)))

    for failure in walker.failures {
        Issue.record(Comment(rawValue: failure), sourceLocation: sourceLocation)
    }
    for unused in allowedNull.subtracting(walker.usedAllowedNull).sorted() {
        Issue.record("allowedNull entry \(unused) didn't match a nil property; remove it", sourceLocation: sourceLocation)
    }
}

private struct FullyPopulatedWalker {
    let allowedNull: Set<String>
    var failures: [String] = []
    var usedAllowedNull: Set<String> = []
    private var visited: Set<ObjectIdentifier> = []

    init(allowedNull: Set<String>) {
        self.allowedNull = allowedNull
    }

    mutating func visit(_ object: NSObject, path: String) {
        guard visited.insert(ObjectIdentifier(object)).inserted else {
            return
        }
        let className = String(describing: type(of: object))

        // Objective-C properties, including those of Swift @objcMembers classes. Computed
        // properties are included; Swift-only stored properties are not.
        var objCPropertyNames: Set<String> = []
        var currentClass: AnyClass? = type(of: object)
        while let someClass = currentClass, someClass != NSObject.self {
            var count: UInt32 = 0
            if let properties = class_copyPropertyList(someClass, &count) {
                for index in 0..<Int(count) {
                    let name = String(cString: property_getName(properties[index]))
                    guard objCPropertyNames.insert(name).inserted else {
                        continue
                    }
                    check(object.value(forKey: name), path: "\(path).\(name)", owner: "\(className).\(name)")
                }
                free(properties)
            }
            currentClass = class_getSuperclass(someClass)
        }

        // Stored Swift properties the runtime doesn't expose, like the private storage behind
        // RadarTimeZone's non-optional computed properties.
        var mirror: Mirror? = Mirror(reflecting: object)
        while let current = mirror {
            for child in current.children {
                guard let label = child.label, !objCPropertyNames.contains(label), !label.hasPrefix("$__lazy_storage_$_") else {
                    continue
                }
                check(unwrapOptional(child.value), path: "\(path).\(label)", owner: "\(className).\(label)")
            }
            mirror = current.superclassMirror
        }
    }

    private mutating func check(_ value: Any?, path: String, owner: String) {
        guard let value else {
            if allowedNull.contains(owner) {
                usedAllowedNull.insert(owner)
            } else {
                failures.append("\(path) is nil. Set it in the full fixture, or add \(owner) to allowedNull with a reason.")
            }
            return
        }

        switch value {
        case let array as NSArray:
            if array.count == 0 {
                failures.append("\(path) is an empty array. Give it at least one element in the full fixture.")
            }
            for (index, element) in array.enumerated() {
                check(unwrapOptional(element), path: "\(path)[\(index)]", owner: owner)
            }
        case let dictionary as NSDictionary:
            if dictionary.count == 0 {
                failures.append("\(path) is an empty dictionary. Give it at least one entry in the full fixture.")
            }
        case let object as NSObject where isRadarModel(object):
            visit(object, path: path)
        default:
            break
        }
    }

    private func isRadarModel(_ object: NSObject) -> Bool {
        NSStringFromClass(type(of: object)).hasPrefix("Radar")
    }

    private func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else {
            return value
        }
        guard let wrapped = mirror.children.first else {
            return nil
        }
        return unwrapOptional(wrapped.value)
    }
}
