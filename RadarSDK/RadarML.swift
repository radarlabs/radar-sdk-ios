//
//  RadarML.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 9/12/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreML

@globalActor
@available(iOS 13.0, *)
actor RadarMLActor {
    static let shared = RadarMLActor()
}

@available(iOS 13.0.0, *)
class RadarML {
    
    var models = [String: MLModel]()
    
    public func downloadModel(name: String) async -> URL? {
        guard let appFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // no app folder
            print("RadarML download failed: no app folder")
            return nil
        }
        do  {
            let modelFolder = appFolder.appendingPathComponent("RadarSDK-IndoorModels")
            var request = URLRequest(url: URL(string: "https://example.com/model.mlmodel")!);
            
            try FileManager.default.createDirectory(at: modelFolder, withIntermediateDirectories: true)
            
            guard let downloadedModelUrl = try await withCheckedThrowingContinuation({ continuation in
                URLSession.shared.downloadTask(with: request) { url, response, error in
                    do {
                        if let url = url {
                            var permenentUrl = modelFolder.appendingPathComponent(name)
                            var excludeFromBackup = URLResourceValues()
                            excludeFromBackup.isExcludedFromBackup = true
                            try permenentUrl.setResourceValues(excludeFromBackup)
                            let resultingUrl = try FileManager.default.replaceItemAt(permenentUrl, withItemAt: url)
                            
                            continuation.resume(returning: resultingUrl)
                        } else {
                            continuation.resume(throwing: NSError())
                        }
                    } catch {
                        continuation.resume(throwing: NSError())
                    }
                }
            }) else {
                // failed to download
                return nil
            }
            
            let compiledModelUrl = try MLModel.compileModel(at: downloadedModelUrl)
            
            var permenentUrl = modelFolder.appendingPathComponent(name)
            var excludeFromBackup = URLResourceValues()
            excludeFromBackup.isExcludedFromBackup = true
            try permenentUrl.setResourceValues(excludeFromBackup)
            let resultingUrl = try FileManager.default.replaceItemAt(permenentUrl, withItemAt: compiledModelUrl)
            
            return resultingUrl
        } catch {
            print("RadarML download failed: \(error)")
            return nil
        }
    }
    
    public func getModel(name: String) async -> MLModel? {
        if models[name] != nil {
            return models[name]
        }
        // model not found, download it
        guard let url = await downloadModel(name: name) else {
            return nil
        }
        guard let model = try? MLModel(contentsOf: url) else {
            return nil
        }
        
        models[name] = model
        return model
    }
    
    public func predict(name: String, features: MLMultiArray) async -> Any? {
        guard let model = getModel(name: name) else {
            return nil
        }
        let prediction = try model.prediction(from: features)
        return prediction
    }
}
