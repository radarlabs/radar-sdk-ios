//
//  RadarLoggerTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

private func waitUntil(timeout: TimeInterval = 5.0, _ check: () async -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await check() { return }
        try? await Task.sleep(nanoseconds: 25_000_000)  // poll every 25ms
    }
}

final class MockRadarDelegate: NSObject, RadarDelegate, @unchecked Sendable {
    var messages = [String]()
    func didLog(message: String) {
        messages.append(message)
    }
}

@Suite
struct RadarLoggerTests {

    @Test func logLevelDebug() async throws {
        let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)
        logger.logLevelOverride = .debug

        logger.debug("debugLog")
        logger.info("infoLog")
        logger.warning("warningLog")
        logger.error("errorLog")

        await waitUntil { delegate.messages.count >= 4 }
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.messages.count == 4)
    }

    @Test func logLevelNone() async throws {
        let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)
        logger.logLevelOverride = RadarLogLevel.none

        logger.debug("debugLog")
        logger.info("infoLog")
        logger.warning("warningLog")
        logger.error("errorLog")

        try await Task.sleep(nanoseconds: 1_000_000_000)
        #expect(delegate.messages.count == 0)
    }

    @Test func logLevelWarning() async throws {
        let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)

        logger.logLevelOverride = RadarLogLevel.warning

        logger.info("infoLog")
        logger.warning("warningLog")

        await waitUntil { delegate.messages.count >= 1 }
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.messages.count == 1)
    }

    @Test func logLevelError() async throws {
        let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)

        logger.logLevelOverride = RadarLogLevel.error

        logger.warning("warningLog")
        logger.error("errorLog")

        await waitUntil { delegate.messages.count >= 1 }
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.messages.count == 1)
    }

    @Test func logLevelInfo() async throws {
        let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)

        logger.logLevelOverride = RadarLogLevel.info

        logger.debug("debugLog")
        logger.info("infoLog")

        await waitUntil { delegate.messages.count >= 1 }
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.messages.count == 1)
    }

    @Test func objectiveCInterfaceWorks() async throws {let logger = RadarLogger()
        let delegate = MockRadarDelegate()

        await logger.setDelegate(delegate)

        logger.logLevelOverride = RadarLogLevel.info

        logger.log(level: .info, message: "hello1")
        logger.log(level: .info, type: .none, message: "hello")
        logger.log(level: .info, type: .none, message: "hello", includeDate: false, includeBattery: false)
        logger.log(level: .info, type: .none, message: "hello", includeDate: false, includeBattery: false, append: false)

        await waitUntil { delegate.messages.count >= 4 }
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(delegate.messages.count == 4)
    }
}
