//
//  RadarLogBufferTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import RadarSDK

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

@Suite(.serialized)
struct RadarLogBufferTests {

    func makeLogsFile(_ name: String) -> String {
        return "test/\(name)-\(UUID().uuidString).txt"
    }

    func removeLogsFile(_ logsFile: String) {
        if let url = file(logsFile) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func withTestPublishableKey(_ operation: () async -> Void) async {
        let previousPublishableKey = RadarSettings.publishableKey
        RadarSettings.publishableKey = "test-key"
        defer { RadarSettings.publishableKey = previousPublishableKey }
        await operation()
    }

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
        let logsFile = makeLogsFile("logs1")
        defer { removeLogsFile(logsFile) }
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
    }

    @Test func flushingBufferResets() async throws {
        await withTestPublishableKey {
            let session = MockURLSession()
            let client = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))

            session.on("\(RadarSettings.host)/v1/logs", [:])

            let logsFile = makeLogsFile("logs2")
            defer { removeLogsFile(logsFile) }
            let buffer = RadarLogBuffer(logsFile: logsFile, logPersistence: true, apiClient: client)
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
        }
    }

    @Test func concurrentFlushesSendOneBatch() async throws {
        await withTestPublishableKey {
            let session = MockURLSession()
            let client = RadarAPIClient(apiHelper: RadarAPIHelper(session: session))
            let requestCounter = RequestCounter()

            session.on(
                { request in
                    requestCounter.increment()
                    Thread.sleep(forTimeInterval: 0.1)
                    return request.url?.absoluteString == "\(RadarSettings.host)/v1/logs"
                }, Data("{}".utf8))

            let logsFile = makeLogsFile("logs-concurrent")
            defer { removeLogsFile(logsFile) }
            let buffer = RadarLogBuffer(logsFile: logsFile, logPersistence: false, apiClient: client)
            await buffer.log(simpleLog("test"))

            await withTaskGroup(of: Void.self) { group in
                group.addTask { await buffer.flush() }
                group.addTask { await buffer.flush() }
                await group.waitForAll()
            }

            #expect(requestCounter.value == 1)
            #expect(await buffer.logs.count == 0)
        }
    }

    @Test func deduplicatesIdenticalLogsBeforeFlush() async throws {
        await withTestPublishableKey {
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

            let logsFile = makeLogsFile("logs-deduplicate")
            defer { removeLogsFile(logsFile) }
            let buffer = RadarLogBuffer(logsFile: logsFile, logPersistence: false, apiClient: client)
            let log = simpleLog("duplicate")
            await buffer.log(log)
            await buffer.log(log)

            await buffer.flush()

            #expect(capturedLogCount.value == 1)
        }
    }

    @Test func purgesBufferWhenFilled() async throws {
        let logsFile = makeLogsFile("logs4")
        defer { removeLogsFile(logsFile) }
        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 5, logPersistence: true)
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
    }
}
