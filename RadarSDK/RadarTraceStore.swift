//
//  RadarTraceStore.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

/// Span records on disk, one file per span, within storage limits.
///
/// Not thread-safe: `RadarTraceManager` calls it only on its serial disk queue.
final class RadarTraceStore {
    static let maxFiles = 500
    static let maxBytes = 512 * 1024
    static let maxAge: TimeInterval = 72 * 60 * 60
    static let staleTempFileAge: TimeInterval = 60

    private static let recordExtension = "json"
    private static let pendingExtension = "pending"
    private static let tempExtension = "tmp"

    /// A span waiting for its session's sampling decision: `<base>.<sessionId>.pending`.
    private struct PendingRecord {
        let name: String
        let sessionId: String
        let base: String
    }

    /// A file in the trace directory.
    struct Entry {
        let name: String
        let size: Int
        let modified: Date
    }

    let directory: URL

    private var fileSequence = 0

    init(directory: URL) {
        self.directory = directory
    }

    static func defaultDirectory() -> URL {
        let root =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return root.appendingPathComponent("RadarSDK", isDirectory: true).appendingPathComponent("traces", isDirectory: true)
    }

    /// Creates the trace directory, excluded from backup. Files are readable after first unlock, so spans recorded
    /// while the device is locked (for example, from a background launch) can still be written.
    func createDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            var url = directory
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
        } catch {
            RadarLogger.shared.error("Could not create trace directory | message = \(error.localizedDescription)", type: .sdkError)
        }
    }

    /// Atomically writes one span record, then enforces the storage limits.
    ///
    /// Each span is one file, `<directory>/<millis>-<sequence>-<uuid>.json`. A span waiting for its session's sampling
    /// decision is written as `<millis>-<sequence>-<uuid>.<sessionId>.pending` instead, and renamed or deleted when the
    /// decision arrives. Names sort oldest first: millis, then a sequence for spans written in the same millisecond.
    /// The record is written to a `.tmp` file, synced, and renamed, so readers never see a partial record.
    func write(_ data: Data, pendingSessionId: String? = nil) {
        let temp = url(for: "span-\(UUID().uuidString.lowercased()).\(Self.tempExtension)")
        defer { try? FileManager.default.removeItem(at: temp) }
        do {
            if !FileManager.default.fileExists(atPath: directory.path) {
                createDirectory()
            }
            try data.write(to: temp, options: [.withoutOverwriting, .completeFileProtectionUntilFirstUserAuthentication])
            let handle = try FileHandle(forWritingTo: temp)
            defer { try? handle.close() }
            try handle.synchronize()

            let millis = Int64(Date().timeIntervalSince1970 * 1000)
            let base = String(format: "%lld-%09ld-%@", millis, fileSequence, UUID().uuidString.lowercased())
            let name = pendingSessionId.map { "\(base).\($0).\(Self.pendingExtension)" } ?? "\(base).\(Self.recordExtension)"
            fileSequence += 1
            try FileManager.default.moveItem(at: temp, to: url(for: name))
            prune()
        } catch {
            RadarLogger.shared.error("Could not persist trace span | message = \(error.localizedDescription)", type: .sdkError)
        }
    }

    /// Uploadable span records, oldest first.
    func records() -> [Entry] {
        entries().filter { Self.pathExtension($0.name) == Self.recordExtension }
    }

    /// Makes a session's pending spans uploadable if it is sampled, or deletes them.
    func resolvePending(sessionId: String, sampled: Bool) {
        for record in pendingRecords() where record.sessionId == sessionId {
            if !sampled {
                remove(record.name)
                continue
            }
            do {
                try FileManager.default.moveItem(at: url(for: record.name), to: url(for: "\(record.base).\(Self.recordExtension)"))
            } catch {
                RadarLogger.shared.error("Could not make pending trace span uploadable | message = \(error.localizedDescription)", type: .sdkError)
            }
        }
    }

    /// Deletes pending spans from every session except `sessionId`. Should be run when the manager is initialized since
    /// during initialize, decisions for other sessions can't arrive anymore, while a request in this process can still
    /// return the current session's.
    func deletePending(exceptSessionId sessionId: String) {
        for record in pendingRecords() where record.sessionId != sessionId {
            remove(record.name)
        }
    }

    func contents(of name: String) -> Data? {
        try? Data(contentsOf: url(for: name))
    }

    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: name).path)
    }

    func remove(_ name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }

    /// Removes stale temp files and expired spans, then evicts the oldest spans until within limits. Pending spans count
    /// toward the limits, so a decision that never arrives can't grow storage.
    func prune() {
        let now = Date()
        let all = entries()
        // Only remove old temp files left by a crash. A recent one may be a write in progress.
        for entry in all where Self.pathExtension(entry.name) == Self.tempExtension {
            if now.timeIntervalSince(entry.modified) > Self.staleTempFileAge {
                remove(entry.name)
            }
        }

        var records: [Entry] = []
        for entry in all where [Self.recordExtension, Self.pendingExtension].contains(Self.pathExtension(entry.name)) {
            if now.timeIntervalSince(entry.modified) > Self.maxAge {
                remove(entry.name)
            } else {
                records.append(entry)
            }
        }

        // Remove oldest first. Note: A batch being uploaded can be evicted too. Its request body is already built, and on success
        // its files would be deleted anyway.
        var bytes = records.reduce(0) { $0 + $1.size }
        var remaining = records[...]
        while remaining.count > Self.maxFiles || bytes > Self.maxBytes, let oldest = remaining.popFirst() {
            bytes -= oldest.size
            remove(oldest.name)
        }
    }

    // MARK: - Private

    /// Pending span records, oldest first.
    private func pendingRecords() -> [PendingRecord] {
        entries().compactMap { entry in
            guard Self.pathExtension(entry.name) == Self.pendingExtension else { return nil }
            let withoutExtension = (entry.name as NSString).deletingPathExtension
            return PendingRecord(
                name: entry.name,
                sessionId: (withoutExtension as NSString).pathExtension,
                base: (withoutExtension as NSString).deletingPathExtension
            )
        }
    }

    private func url(for name: String) -> URL {
        directory.appendingPathComponent(name, isDirectory: false)
    }

    /// Every file in the trace directory, sorted by name.
    private func entries() -> [Entry] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys) else {
            return []
        }
        return urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return Entry(
                name: url.lastPathComponent,
                size: values?.fileSize ?? 0,
                modified: values?.contentModificationDate ?? .distantPast
            )
        }
        .sorted { $0.name < $1.name }
    }

    private static func pathExtension(_ name: String) -> String {
        (name as NSString).pathExtension
    }
}
