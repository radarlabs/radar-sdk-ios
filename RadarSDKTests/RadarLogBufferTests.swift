//
//  RadarLogBufferTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

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
        // buffer initialization is async, wait for logs to be loaded
        try? await Task.sleep(nanoseconds: 100_000_000)
        
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
        try? await Task.sleep(nanoseconds: 100_000_000)
        
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
    
    @Test func initializeWithLogPersistenceLoadsBuffer() async throws {
        let logsFile = "test/logs3.txt"
        let file = RadarFileStorage(fileName: "\(logsFile)")
        
        let logs = Data([
            try! JSONEncoder().encode(simpleLog("persist1")),
            try! JSONEncoder().encode(simpleLog("persist2")),
            try! JSONEncoder().encode(simpleLog("persist3")),
        ].map { $0 + "\n".data(using: .utf8)! }.joined())
        
        file?.write(data: logs)
        
        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 5, logPersistence: true)
        
        // buffer initialization is async, wait for logs to be loaded
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(await buffer.logs.count == 3)
        
        file?.delete()
    }
    
    @Test func purgesBufferWhenFilled() async throws {
        let logsFile = "test/logs4.txt"
        let buffer = RadarLogBuffer(logsFile: logsFile, maxLogs: 10, keep: 5, logPersistence: true)
        // buffer initialization is async, wait for logs to be loaded
        try? await Task.sleep(nanoseconds: 100_000_000)
        
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
