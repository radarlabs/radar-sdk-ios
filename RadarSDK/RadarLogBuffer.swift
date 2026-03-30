//
//  RadarLogBuffer.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import OSLog


@available(iOS 13.0, *)
actor RadarLogBuffer {
    var logs = [RadarLog]()
    
    // the logs file is a full reflection of the
    let logsFile = RadarFileStorageData(fileName: "logs")
    
    let MAX_LOGS = 500 // make configurable
    let KEEP = 250
    
    init() {
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
        
        let useLogPersistence = RadarSettings.sdkConfiguration?.useLogPersistence ?? false
        if logs.count > MAX_LOGS {
            logs.removeFirst(logs.count - KEEP)
            // write the current logs list to file
            if useLogPersistence, let logsFile {
                logsFile.write(data: Data())
                for log in logs {
                    if let data = try? JSONEncoder().encode(log) {
                        logsFile.append(data: data)
                    }
                }
            }
        } else {
            if useLogPersistence, let logsFile {
                if let data = try? JSONEncoder().encode(log) {
                    logsFile.append(data: data)
                }
            }
        }
    }
    
    func flush() async {
        do {
            if #available(iOS 13.0, *) {
                try await RadarAPIClient.shared.sendLogs(logs: logs)
            }
            logs = []
            let useLogPersistence = RadarSettings.sdkConfiguration?.useLogPersistence ?? false
            if useLogPersistence, let logsFile {
                logsFile.write(data: Data())
            }
        } catch {
            // failed to flush logs, keep existing buffer
        }
    }
}

