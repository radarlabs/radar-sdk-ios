//
//  RadarML.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/12/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreML

@available(iOS 13.0.0, *)
class RadarML {
    
    // should not be ran on main thread
    public static func downloadModel(name: String) async -> URL? {
        guard let appFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // no app folder
            return nil
        }
        do  {
            var excludeFromBackup = URLResourceValues()
            excludeFromBackup.isExcludedFromBackup = true
            
            var modelFolder = appFolder.appendingPathComponent("RadarSDK-IndoorModels")
            var request = URLRequest(url: URL(string: "https://example.com/model.mlmodel")!);
            
            try FileManager.default.createDirectory(at: modelFolder, withIntermediateDirectories: true)
            
            guard let downloadedModelUrl = try await withCheckedThrowingContinuation({ continuation in
                URLSession.shared.downloadTask(with: request, completionHandler: { url, response, error in
                    do {
                        if let url = url {
                            var permenentUrl = modelFolder.appendingPathComponent(name)
                            try permenentUrl.setResourceValues(excludeFromBackup)
                            try FileManager.default.replaceItemAt(permenentUrl, withItemAt: url)
                            
                            continuation.resume(returning: permenentUrl)
                        } else {
                            continuation.resume(throwing: NSError())
                        }
                    } catch {
                        continuation.resume(throwing: NSError())
                    }
                })
            }) else {
                // failed to download
                return nil
            }
            
            let compiledModelUrl = try MLModel.compileModel(at: downloadedModelUrl)
            
            var permenentUrl = modelFolder.appendingPathComponent(name)
            try permenentUrl.setResourceValues(excludeFromBackup)
            try FileManager.default.replaceItemAt(permenentUrl, withItemAt: compiledModelUrl)
            
            return permenentUrl
        } catch {
            return nil
        }
    }
    
    public static func predict(name: String, features: [String: Any]) {
        
    }
}
