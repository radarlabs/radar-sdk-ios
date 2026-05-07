//
//  RadarLogBuffer.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import OSLog


@available(iOS 13.0, *)
actor RadarLogBuffer {
    
    static let shared = RadarLogBuffer()
    
    var logs = [RadarLog]()
    
    // the logs file is a full reflection of the logs
    let logsFile: RadarFileStorage?

    let MAX_LOGS: Int
    let KEEP: Int
    
    let NEW_LINE = "\n".data(using: .utf8)!
    
    // in testing mode, allow overriding useLogPersistence
    var useLogPersistenceOverride: Bool? = nil
    var useLogPersistence: Bool {
        get {
            useLogPersistenceOverride ?? RadarSettings.sdkConfiguration?.useLogPersistence ?? false
        }
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
