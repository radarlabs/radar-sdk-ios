//
//  RadarLogBuffer.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import OSLog

class RadarLogBuffer {
    
    let logsFile = RadarFileStorageData(fileName: "logs")
    
    let logs = [RadarLog]()
    
    let MAX_FILE_SIZE = 4_000_000 // 4MB
    
    func log(message: String) {
        
        
        if RadarSettings.sdkConfiguration?.useLogPersistence == true {
            guard let handle = logsFile?.handle else {
                return
            }
            
            
            // replace newlines with space, every new line will be a log entry
            let data = (message.replacingOccurrences(of: "\n", with: " ") + "\n").data(using: .utf8)
            
            let fileSize = handle.seekToEndOfFile()
            
            if fileSize >= MAX_FILE_SIZE {
                let lines = logsFile
                
            }
        }
    }
}
