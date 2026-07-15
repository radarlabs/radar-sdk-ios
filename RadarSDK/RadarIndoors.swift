//
//  RadarIndoor.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/2/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Foundation

@globalActor
public actor RadarIndoorsActor {
    public static let shared = RadarIndoorsActor()
}

@RadarIndoorsActor
class RadarSDKIndoors {
    let instance: NSObject
    init?() {
        // Fail the initializer when the optional RadarSDKIndoors framework isn't linked, so
        // `RadarSDKIndoors()` is nil and the `guard let sdk` checks downstream mean what they say.
        guard let cls = NSClassFromString("RadarSDKIndoors") as? NSObject.Type else {
            return nil
        }
        instance = cls.init()
    }

    public func useModel(model: String, getModelData: @convention(block) @escaping @Sendable () -> URL?) async {
        guard let bridge = RadarSwift.bridge else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("useModelWithName:getModelData:completionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [model, getModelData, completion])
        }
    }

    func getLocation() async -> CLLocation? {
        guard let bridge = RadarSwift.bridge else { return nil }
        return await withCheckedContinuation { continuation in
            let completion: @convention(block) (CLLocation?) -> Void = { result in
                continuation.resume(returning: result)
            }
            let selector = NSSelectorFromString("getLocationWithCompletionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [completion])
        }
    }

    func start() async {
        guard let bridge = RadarSwift.bridge else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("startWithCompletionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [completion])
        }
    }

    func stop() async {
        guard let bridge = RadarSwift.bridge else { return }
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let selector = NSSelectorFromString("stopWithCompletionHandler:")
            bridge.invoke(target: instance, selector: selector, args: [completion])
        }
    }

    public func setOnLocationUpdate(_ block: @convention(block) @escaping @Sendable (CLLocation) -> Void) {
        guard let bridge = RadarSwift.bridge else { return }
        let selector = NSSelectorFromString("setOnLocationUpdate:")
        bridge.invoke(target: instance, selector: selector, args: [block])
    }
}

@RadarIndoorsActor
@objc(RadarIndoors) @objcMembers
internal class RadarIndoors: NSObject {
    public static let shared = RadarIndoors()

    var currentModelId: String?

    /**
     RadarSDKIndoors calls
     */
    let sdk = RadarSDKIndoors()

    let onLocationUpdate: @Sendable @convention(block) (CLLocation) -> Void = { location in
        Task {
            await RadarDelegateHolder.didUpdateClientLocation(location: location, stopped: false, source: .indoors)
            RadarLogger.shared.debug("indoor location update")
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
                currentModelId = nil
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
        // This callback is invoked synchronously by the RadarSDKIndoors framework, and only on a
        // local-cache miss, to fetch the model's data from the server. The framework's API requires a
        // URL returned synchronously, so we bridge the async download onto a detached Task and block
        // on a semaphore. The result crosses back through a reference box whose read is ordered after
        // the write by the semaphore's signal/wait. This is only safe because the framework invokes
        // this block off the Swift concurrency cooperative pool; fully removing the blocking wait
        // requires an async data-provider API on RadarSDKIndoors (tracked as follow-up). See PR.
        let getModelData: @Sendable @convention(block) () -> URL? = { @Sendable in
            RadarLogger.shared.debug("useModel getData callback called")
            let semaphore = DispatchSemaphore(value: 0)
            let box = RadarIndoorsModelDataBox()

            Task.detached {
                box.url = await RadarIndoors.downloadModelData(modelId: modelId)
                semaphore.signal()
            }

            semaphore.wait()  // Blocks the calling (framework) thread until the download resolves
            return box.url
        }
        await sdk.useModel(model: "\(modelId).mlmodel", getModelData: getModelData)
        sdk.setOnLocationUpdate(onLocationUpdate)
        await sdk.start()
        // Record the active model only once start() has returned, so a failure earlier in the
        // chain doesn't leave currentModelId set and short-circuit the next updateTracking pass.
        currentModelId = modelId
    }

    public func getLocation() async -> CLLocation? {
        guard let sdk else {
            return nil
        }
        return await sdk.getLocation()
    }

    // Downloads the mlmodel asset for a geofence's active indoor model to a temp file.
    // nonisolated so it can run on a detached Task without hopping onto RadarIndoorsActor.
    nonisolated static func downloadModelData(modelId: String) async -> URL? {
        do {
            let data = try await RadarAPIClient.shared.getAsset(url: "models/\(modelId)/rssi_lstm.mlmodel")
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            // Write to a deterministic per-model path so re-downloading the same model overwrites
            // its file rather than leaking a new UUID-named blob into tmp on every model switch.
            let fileName = modelId.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? modelId
            let fileURL = temporaryDirectoryURL.appendingPathComponent("radar_indoor_\(fileName).mlmodel")
            try data.write(to: fileURL)
            return fileURL
        } catch {
            RadarLogger.shared.warning("Failed to get data for model \(modelId): \(error.localizedDescription)")
            return nil
        }
    }
}

// Transfers a URL from a detached download Task back to the synchronous getModelData callback.
// The read is ordered after the write by the bridging semaphore, so unchecked Sendable is sound.
private final class RadarIndoorsModelDataBox: @unchecked Sendable {
    var url: URL?
}
