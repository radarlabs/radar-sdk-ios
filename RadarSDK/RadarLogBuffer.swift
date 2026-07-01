//
//  RadarLogBuffer.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import OSLog

actor RadarLogBuffer {

    static let shared = RadarLogBuffer()

    var logs = [RadarLog]()

    // the logs file is a full reflection of the logs
    let logsFile: RadarFileStorage?

    let MAX_LOGS: Int  // swiftlint:disable:this identifier_name
    let KEEP: Int

    let NEW_LINE = "\n".data(using: .utf8)!  // swiftlint:disable:this identifier_name non_optional_string_data_conversion

    // in testing mode, allow overriding useLogPersistence
    var useLogPersistenceOverride: Bool?
    var useLogPersistence: Bool {
        useLogPersistenceOverride ?? RadarSettings.sdkConfiguration?.useLogPersistence ?? false
    }

    let apiClient: RadarAPIClient

    // Test hook: lets tests await the initial async log load deterministically instead of
    // racing a wall-clock timeout, which is flaky under CI's saturated cooperative thread pool.
    // A continuation-based signal is used (rather than storing the load Task itself) because
    // actor initializers disallow further isolated-property writes once `self` has been
    // captured by an escaping closure, which the fire-and-forget load Task below requires.
    private var isLogsLoaded = false
    private var logsLoadedContinuations = [CheckedContinuation<Void, Never>]()

    init(logsFile: String = "persistent_logs.txt", maxLogs: Int = 500, keep: Int = 250, logPersistence: Bool? = nil, apiClient: RadarAPIClient = RadarAPIClient.shared) {
        self.logsFile = RadarFileStorage(fileName: logsFile)
        self.MAX_LOGS = maxLogs
        self.KEEP = keep
        self.useLogPersistenceOverride = logPersistence
        self.apiClient = apiClient

        Task { [weak self] in
            await self?.loadLogs()
        }
    }

    /// Test hook: awaits the initial log-loading task so tests can assert on `logs`
    /// deterministically instead of polling against a wall-clock timeout.
    func awaitInitialLoad() async {
        if isLogsLoaded { return }
        await withCheckedContinuation { continuation in
            logsLoadedContinuations.append(continuation)
        }
    }

    func loadLogs() async {
        defer { markLogsLoaded() }
        guard let logsFile, #available(iOS 15.0, *) else { return }

        do {
            for try await line in logsFile.file.lines {
                guard let data = line.data(using: .utf8) else {
                    continue
                }
                guard let log = try? JSONDecoder().decode(RadarLog.self, from: data) else {
                    continue
                }
                logs.append(log)
            }
        } catch {

        }
    }

    private func markLogsLoaded() {
        isLogsLoaded = true
        let continuations = logsLoadedContinuations
        logsLoadedContinuations = []
        continuations.forEach { $0.resume() }
    }

    func log(_ log: RadarLog) {
        logs.append(log)

        if logs.count > MAX_LOGS {
            logs.removeFirst(logs.count - KEEP)
            // write the current logs list to file
            if useLogPersistence, let logsFile {
                logsFile.write(data: Data())
                for log in logs {
                    if let data = try? JSONEncoder().encode(log) {
                        logsFile.append(data: data + NEW_LINE)
                    }
                }
            }
        } else {
            if useLogPersistence, let logsFile {
                if let data = try? JSONEncoder().encode(log) {
                    logsFile.append(data: data + NEW_LINE)
                }
            }
        }
    }

    func flush() async {
        do {
            try await apiClient.sendLogs(logs: logs)
            logs = []
            if useLogPersistence, let logsFile {
                logsFile.write(data: Data())
            }
        } catch {
            // failed to flush logs, keep existing buffer
        }
    }
}
