//
//  RadarLogBuffer.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import OSLog

actor RadarLogBuffer {
    
    let logsFile = RadarFileStorageData(fileName: "logs")
    
    var logs = [RadarLog]()
    
    let MAX_LOGS = 500 // make configurable
    let KEEP = 200
    
    init() {
        if #available(iOS 15.0, *) {
            Task {
                await loadLogs()
            }
        }
    }
    
    @available(iOS 15.0, *)
    func loadLogs() async {
        guard let logsFile else { return }
        
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
    
    func flush() {
        
    }
}

