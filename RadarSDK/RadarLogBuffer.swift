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

    // A second flush can start while the first upload waits on the network.
    private var isFlushing = false

    private struct LogIdentity: Hashable {
        let createdAt: Date
        let level: String
        let type: String
        let message: String
        let includeDate: Bool
        let battery: Float?
    }

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

        Task { [weak self] in
            await self?.loadLogs()
        }
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

        let uniqueLogs = deduplicated(logs)
        if uniqueLogs.count != logs.count {
            logs = uniqueLogs
            rewriteLogsFile()
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

    // A killed process can leave a log to be replayed from persistent storage.
    private func deduplicated(_ logs: [RadarLog]) -> [RadarLog] {
        var seen = Set<LogIdentity>()
        return logs.filter { log in
            let identity = LogIdentity(
                createdAt: log.createdAt,
                level: log.level.toString(),
                type: log.type.toString(),
                message: log.message,
                includeDate: log.includeDate,
                battery: log.battery
            )
            return seen.insert(identity).inserted
        }
    }

    private func rewriteLogsFile() {
        guard let logsFile else { return }
        logsFile.write(data: Data())
        for log in logs {
            if let data = try? JSONEncoder().encode(log) {
                logsFile.append(data: data + NEW_LINE)
            }
        }
    }

    private func persistLogs() {
        guard useLogPersistence else { return }
        rewriteLogsFile()
    }

    func flush() async {
        guard !isFlushing else { return }

        logs = deduplicated(logs)
        guard !logs.isEmpty else { return }

        isFlushing = true
        let logsToSend = logs
        logs.removeAll()
        defer { isFlushing = false }

        do {
            try await apiClient.sendLogs(logs: logsToSend)
            persistLogs()
        } catch {
            logs.insert(contentsOf: logsToSend, at: 0)
            persistLogs()
        }
    }
}
