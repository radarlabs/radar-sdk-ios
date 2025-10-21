//
//  RadarML.swift
//  Example
//
//  Created by ShiCheng Lu on 10/21/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreML

@globalActor
@available(iOS 13.0, *)
actor RadarMLActor {
    static let shared = RadarMLActor()
}

@RadarMLActor
@available(iOS 13.0.0, *)
class RadarML {
    
    static var shared = RadarML()
    
    var models = [String: MLModel]()
    
    public func downloadModel(name: String) async -> URL? {
        guard let appFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // no app folder
            print("RadarML download failed: no app folder")
            return nil
        }
        
        let modelsFolder = appFolder.appendingPathComponent("RadarSDK-IndoorModels")
        guard let requestUrl = URL(string: "https://bailey-nonnebulous-nonaccidentally.ngrok-free.dev/model/\(name)") else {
            print("RadarML download failed: invalid model url")
            return nil
        }
        let request = URLRequest(url: requestUrl);
        
        do  {
            try FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true)
        } catch {
            print("RadarML download: failed to create models folder \(error)")
            return nil
        }
        
        // downloads and compiles the model
        let modelUrl = try? await withCheckedThrowingContinuation({ continuation in
            URLSession.shared.downloadTask(with: request) { url, response, error in
                guard let url = url else {
                    continuation.resume(returning: nil as URL?)
                    return
                }
                
                do {
                    let compiledModelUrl = try MLModel.compileModel(at: url)
                    
                    var permenentUrl = modelsFolder.appendingPathComponent("\(name).mlmodelc")
                    // delete the previous version if it exists
                    if FileManager.default.fileExists(atPath: permenentUrl.path) {
                        try FileManager.default.removeItem(at: permenentUrl)
                    }
                    // move the new item to its permenent location
                    try FileManager.default.moveItem(at: compiledModelUrl, to: permenentUrl)
                    // mark it to be excluded from iCloud backup
                    var excludeFromBackup = URLResourceValues()
                    excludeFromBackup.isExcludedFromBackup = true
                    try permenentUrl.setResourceValues(excludeFromBackup)
                    
                    continuation.resume(returning: permenentUrl)
                } catch {
                    print("RadarML download: \(error)")
                    continuation.resume(returning: nil as URL?)
                }
            }.resume()
        })
        return modelUrl
    }
    
    public func getModel(name: String) async -> MLModel? {
        if models[name] != nil {
            print("RadarML using cached model: \(name)")
            return models[name]
        }
        print("RadarML not found")
        // model not found, download it
        guard let url = await downloadModel(name: name) else {
            return nil
        }
        guard let model = try? MLModel(contentsOf: url) else {
            print("Model loading failed")
            return nil
        }
        
        models[name] = model
        return model
    }
    
    public func predict(name: String, features: any MLFeatureProvider) async -> MLFeatureProvider? {
        guard let model = await getModel(name: name) else {
            return nil
        }
        do {
            let prediction = try model.prediction(from: features)
            return prediction
        } catch {
            print("RadarML prediction failed \(error)")
            return nil
        }
    }
}
