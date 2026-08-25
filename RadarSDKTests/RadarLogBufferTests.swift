//
//  RadarLogBufferTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

private func waitUntil(timeout: TimeInterval = 5.0, _ check: () async -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await check() { return }
        try? await Task.sleep(nanoseconds: 25_000_000)
    }
}

private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedValue
    }

    func increment() {
        lock.lock()
        storedValue += 1
        lock.unlock()
    }

    func set(_ value: Int) {
        lock.lock()
        storedValue = value
        lock.unlock()
    }
}

@Suite
struct RadarLogBufferTests {

    func simpleLog(_ message: String) -> RadarLog {
        return RadarLog(level: .info, message: message, type: .none, createdAt: Date(), includeDate: true, battery: 1.0)
    }

    func file(_ file: String) -> URL? {
        guard let documents = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // failed to find directory
            return nil
        }
        return documents.appendingPathComponent("RadarSDK/\(file)")
    }

    func logsFrom(url: URL) -> [String] {
        do {
            let data = try Data(contentsOf: url)
            let string = String(data: data, encoding: .utf8)
            let logs = string?.split(separator: "\n").map { String($0) }
            if let logs {
                return logs
            } else {
                print("string parsing error")
                return []
            }
        } catch {
            print("Error reading")
            return []
        }
    }

    @Test func logsSavesToBuffer() async throws {
        let logsFile = "test/logs1.txt"
        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 10, logPersistence: true)
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await buffer.log(simpleLog("test1"))
        await buffer.log(simpleLog("test2"))
        await buffer.log(simpleLog("test3"))

        #expect(await buffer.logs.count == 3)

        guard let file = file(logsFile) else {
            Issue.record("logsFile should not produce invalid URL")
            return
        }

        let fileLogs = logsFrom(url: file)
        #expect(fileLogs.count == 3)

        try? FileManager.default.removeItem(at: file)
    }

    @Test func flushingBufferResets() async throws {
        RadarSettings.publishableKey = "test-key"
        let session = MockURLSession()
        let client = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))

        session.on("\(RadarSettings.host)/v1/logs", [:])

        let logsFile = "test/logs2.txt"
        let buffer = RadarLogBuffer(logsFile: logsFile, logPersistence: true, apiClient: client)
        // buffer initialization is async, wait for logs to be loaded
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await buffer.log(simpleLog("test1"))
        await buffer.log(simpleLog("test2"))
        await buffer.log(simpleLog("test3"))

        await buffer.flush()

        #expect(await buffer.logs.count == 0)

        guard let file = file(logsFile) else {
            Issue.record("logsFile should not produce invalid URL")
            return
        }

        let fileLogs = logsFrom(url: file)
        #expect(fileLogs.count == 0)

        try? FileManager.default.removeItem(at: file)
    }

    @Test func concurrentFlushesSendOneBatch() async throws {
        RadarSettings.publishableKey = "test-key"
        let session = MockURLSession()
        let client = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
        let requestCounter = RequestCounter()

        session.on(
            { request in
                requestCounter.increment()
                Thread.sleep(forTimeInterval: 0.1)
                return request.url?.absoluteString == "\(RadarSettings.host)/v1/logs"
            }, Data("{}".utf8))

        let buffer = RadarLogBuffer(logsFile: "test/logs-concurrent.txt", logPersistence: false, apiClient: client)
        await buffer.log(simpleLog("test"))

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await buffer.flush() }
            group.addTask { await buffer.flush() }
            await group.waitForAll()
        }

        #expect(requestCounter.value == 1)
        #expect(await buffer.logs.count == 0)
    }

    @Test func deduplicatesIdenticalLogsBeforeFlush() async throws {
        RadarSettings.publishableKey = "test-key"
        let session = MockURLSession()
        let client = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
        let capturedLogCount = RequestCounter()

        session.on(
            { request in
                if let body = request.httpBody,
                    let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                    let logs = object["logs"] as? [[String: Any]]
                {
                    capturedLogCount.set(logs.count)
                }
                return request.url?.absoluteString == "\(RadarSettings.host)/v1/logs"
            }, Data("{}".utf8))

        let buffer = RadarLogBuffer(logsFile: "test/logs-deduplicate.txt", logPersistence: false, apiClient: client)
        let log = simpleLog("duplicate")
        await buffer.log(log)
        await buffer.log(log)

        await buffer.flush()

        #expect(capturedLogCount.value == 1)
    }

    @Test func deduplicatesPersistedLogsOnLoad() async throws {
        let logsFile = "test/logs-deduplicate-persisted.txt"
        let storage = RadarFileStorage(fileName: logsFile)
        let log = simpleLog("duplicate")
        let encodedLog = try! JSONEncoder().encode(log)  // swiftlint:disable:this force_try
        let line = encodedLog + "\n".data(using: .utf8)!  // swiftlint:disable:this non_optional_string_data_conversion
        storage?.write(data: line + line)

        let buffer = RadarLogBuffer(logsFile: logsFile, logPersistence: true)
        await waitUntil { await buffer.logs.count == 1 }

        #expect(await buffer.logs.count == 1)
        try? await Task.sleep(nanoseconds: 100_000_000)

        if let file = file(logsFile) {
            #expect(logsFrom(url: file).count == 1)
        }
        storage?.delete()
    }

    @Test func initializeWithLogPersistenceLoadsBuffer() async throws {
        let logsFile = "test/logs3.txt"
        let file = RadarFileStorage(fileName: "\(logsFile)")

        let logs = Data(
            [
                try! JSONEncoder().encode(simpleLog("persist1")),  // swiftlint:disable:this force_try
                try! JSONEncoder().encode(simpleLog("persist2")),  // swiftlint:disable:this force_try
                try! JSONEncoder().encode(simpleLog("persist3")),  // swiftlint:disable:this force_try
            ].map { $0 + "\n".data(using: .utf8)! }.joined())  // swiftlint:disable:this non_optional_string_data_conversion

        file?.write(data: logs)

        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 5, logPersistence: true)

        await waitUntil { await buffer.logs.count >= 3 }
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(await buffer.logs.count == 3)

        file?.delete()
    }

    @Test func purgesBufferWhenFilled() async throws {
        let logsFile = "test/logs4.txt"
        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 5, logPersistence: true)
        // buffer initialization is async, wait for logs to be loaded
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        guard let file = file(logsFile) else {
            Issue.record("logsFile should not produce invalid URL")
            return
        }

        await buffer.log(simpleLog("test1"))
        await buffer.log(simpleLog("test2"))
        await buffer.log(simpleLog("test3"))
        await buffer.log(simpleLog("test4"))
        await buffer.log(simpleLog("test5"))
        await buffer.log(simpleLog("test6"))
        await buffer.log(simpleLog("test7"))
        await buffer.log(simpleLog("test8"))
        await buffer.log(simpleLog("test9"))
        await buffer.log(simpleLog("test10"))

        #expect(await buffer.logs.count == 10)
        let fileLogs = logsFrom(url: file)
        #expect(fileLogs.count == 10)

        // 11th log should trigger a purge
        await buffer.log(simpleLog("test11"))

        #expect((await buffer.logs.count) == 5)

        let fileLogsAfterPurge = logsFrom(url: file)
        #expect(fileLogsAfterPurge.count == 5)

        try? FileManager.default.removeItem(at: file)
    }
}
