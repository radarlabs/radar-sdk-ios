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

    // Retains the async persistence load started in init so callers (and tests) can await
    // it deterministically instead of racing it with wall-clock sleeps.
    private var loadLogsTask: Task<Void, Never>?

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

    init(logsFile: String = "persistent_logs.txt", maxLogs: Int = 500, keep: Int = 250, logPersistence: Bool? = nil, apiClient: RadarAPIClient = RadarAPIClient.shared) {
        self.logsFile = RadarFileStorage(fileName: logsFile)
        self.MAX_LOGS = maxLogs
        self.KEEP = keep
        self.useLogPersistenceOverride = logPersistence
        self.apiClient = apiClient

        // Kick off the initial persistence load. Routed through waitForInitialLoad so the
        // load Task is created (and can be awaited) from an isolated context.
        Task { [weak self] in
            await self?.waitForInitialLoad()
        }
    }

    // Starts the persistence load once (idempotent) and awaits its completion. Deterministic
    // alternative to sleeping and hoping the async load kicked off in init has finished.
    func waitForInitialLoad() async {
        if loadLogsTask == nil {
            loadLogsTask = Task { [weak self] in
                await self?.loadLogs()
            }
        }
        await loadLogsTask?.value
    }

    func loadLogs() async {
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
