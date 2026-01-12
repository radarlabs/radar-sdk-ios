//
//  RadarIndoor.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation

@globalActor
@available(iOS 13.0, *)
public actor RadarIndoorsActor {
    public static let shared = RadarIndoorsActor()
}

@RadarIndoorsActor
@available(iOS 13.0, *)
class RadarSDKIndoors {
    let instance: NSObject?
    init? () {
        if let cls = NSClassFromString("RadarSDKIndoors") as? NSObject.Type {
            instance = cls.init()
        } else {
            instance = nil
        }
    }
    
    public func useModel(model: String, getModelData: @convention(block) @escaping @Sendable () -> URL?) async {
        guard let bridge = RadarSwift.bridge, let instance else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("useModelWithName:getModelData:completionHandler:")
            bridge.invoke(target:instance, selector:selector, args: [model, getModelData, completion])
        }
        
        
    }
    
    func getLocation() async -> CLLocation? {
        guard let bridge = RadarSwift.bridge, let instance else { return nil }
        return await withCheckedContinuation { continuation in
            let completion: @convention(block) (CLLocation?) -> Void = { result in
                continuation.resume(returning: result)
            }
            let selector = NSSelectorFromString("getLocationWithCompletionHandler:")
            bridge.invoke(target:instance, selector:selector, args: [completion])
        }
    }
    
    func start() async {
        guard let bridge = RadarSwift.bridge, let instance else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("startWithCompletionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [completion])
        }
    }
    
    func stop() async {
        guard let bridge = RadarSwift.bridge, let instance else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("stopWithCompletionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [completion])
        }
    }
    
    public func setOnLocationUpdate(_ block: @convention(block) @escaping @Sendable (CLLocation) -> Void) {
        guard let bridge = RadarSwift.bridge, let instance else { return }
        let selector = NSSelectorFromString("setOnLocationUpdate:")
        bridge.invoke(target: instance, selector: selector, args: [block])
    }
}

@RadarIndoorsActor
@available(iOS 13.0, *)
@objc(RadarIndoors) @objcMembers
internal class RadarIndoors: NSObject {
    public static let shared = RadarIndoors()
    
    var currentModelId: String? = nil
    
    /**
     RadarSDKIndoors calls
     */
    let sdk = RadarSDKIndoors()
    
    let onLocationUpdate: @Sendable @convention(block) (CLLocation) -> Void = { location in
        Task {
            await RadarDelegateHolder.didUpdateClientLocation(location: location, stopped: false, source: .indoors)
            print("updated location")
        }
    }
    
    public func updateTracking(user: RadarUser) async {
        guard let sdk else {
            if Radar.getTrackingOptions().useIndoorScan {
                // if using indoor scan, we're expecting the IndoorSDK to be available, so log a warning if it's not available
                RadarLogger.shared.warning("RadarIndoors class is nil")
            }
            return
        }
        if !Radar.getTrackingOptions().useIndoorScan {
            // stop indoor updates if it's on
            if currentModelId != nil {
                await sdk.stop()
            }
            return
        }
        if user.geofences?.contains(where: { $0.activeIndoorModelId != nil && ($0.activeIndoorModelId == currentModelId) }) == true {
            RadarLogger.shared.debug("model already in use")
            return
        }
        guard let modelId = user.geofences?.first(where: { $0.activeIndoorModelId != nil })?.activeIndoorModelId else {
            // no model id in current geofences
            RadarLogger.shared.debug("found no model id in current geofences")
            return
        }
        currentModelId = modelId
        // this is a function that retrieves the data of the mlmodel from the server synchronously
        // which will be called if the model cannot be found in the local cache
        let getModelData: @Sendable @convention(block) () -> URL? = { @Sendable in
            RadarLogger.shared.debug("useModel getData callback called")
            let semaphore = DispatchSemaphore(value: 0)
            var result: URL?

            Task {
                do {
                    let data = try await RadarAPIClient.shared.getAsset(url: "models/\(modelId)/rssi_lstm.mlmodel")
                    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString + ".mlmodel")

                    try data.write(to: fileURL)
                    result = fileURL
                    semaphore.signal()
                } catch {
                    // TODO: log an error
                    RadarLogger.shared.debug("Failed to get data for model")
                    result = nil
                    semaphore.signal()
                }
            }

            semaphore.wait() // Blocks the current thread
            return result
        }
        await sdk.useModel(model: "\(modelId).mlmodel", getModelData:getModelData)
        sdk.setOnLocationUpdate(onLocationUpdate)
        await sdk.start()
        
        
    }
    
    public func getLocation() async -> CLLocation? {
        guard let sdk else {
            return nil
        }
        return await sdk.getLocation()
    }
}
