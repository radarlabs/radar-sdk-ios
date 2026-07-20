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
    // Write-once in the nonisolated initializer, only read from actor-isolated methods afterwards,
    // so nonisolated(unsafe) is sound and lets the init run off the actor.
    nonisolated(unsafe) let instance: NSObject

    nonisolated static let useModelSelector = NSSelectorFromString("useModelWithConfig:completionHandler:")
    nonisolated static let getLocationSelector = NSSelectorFromString("getLocationWithCompletionHandler:")
    nonisolated static let startSelector = NSSelectorFromString("startWithCompletionHandler:")
    nonisolated static let stopSelector = NSSelectorFromString("stopWithCompletionHandler:")
    nonisolated static let setOnLocationUpdateSelector = NSSelectorFromString("setOnLocationUpdate:")

    nonisolated init?() {
        // Fail the initializer when the optional RadarSDKIndoors framework isn't linked, so
        // `RadarSDKIndoors()` is nil and the `guard let sdk` checks downstream mean what they say.
        guard let cls = NSClassFromString("RadarSDKIndoors") as? NSObject.Type else {
            return nil
        }
        let instance = cls.init()
        // Verify the linked class actually is our RadarSDKIndoors by requiring it to respond to
        // every selector we call, matching RadarSDKFraud.init?(instance:). If any is missing the
        // framework is the wrong shape (or an older release), so fail rather than trap at perform.
        guard instance.responds(to: RadarSDKIndoors.useModelSelector),
            instance.responds(to: RadarSDKIndoors.getLocationSelector),
            instance.responds(to: RadarSDKIndoors.startSelector),
            instance.responds(to: RadarSDKIndoors.stopSelector),
            instance.responds(to: RadarSDKIndoors.setOnLocationUpdateSelector)
        else {
            return nil
        }
        self.instance = instance
    }

    // All selectors are validated in init?, so no per-call `responds(to:)` guard is needed here.
    public func useModel(model: String, getModelData: @convention(block) @escaping @Sendable () -> URL?) async {
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            let config: [String: Any] = ["name": model, "getModelData": getModelData]
            instance.perform(RadarSDKIndoors.useModelSelector, with: config, with: completion)
        }
    }

    func getLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            let completion: @convention(block) (CLLocation?) -> Void = { result in
                continuation.resume(returning: result)
            }
            instance.perform(RadarSDKIndoors.getLocationSelector, with: completion)
        }
    }

    func start() async {
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            instance.perform(RadarSDKIndoors.startSelector, with: completion)
        }
    }

    func stop() async {
        await withCheckedContinuation { continuation in
            let completion: @convention(block) () -> Void = {
                continuation.resume()
            }
            instance.perform(RadarSDKIndoors.stopSelector, with: completion)
        }
    }

    public func setOnLocationUpdate(_ block: @convention(block) @escaping @Sendable (CLLocation) -> Void) {
        instance.perform(RadarSDKIndoors.setOnLocationUpdateSelector, with: block)
    }
}

@RadarIndoorsActor
@objc(RadarIndoors) @objcMembers
internal class RadarIndoors: NSObject {
    // `shared` and `init()` are nonisolated so the Objective-C tracking code can obtain the
    // singleton without running on the RadarIndoorsActor executor. Accessing an actor-isolated
    // member synchronously from off-actor traps at runtime ("Incorrect actor executor
    // assumption"), which is what `[[RadarIndoors shared] ...]` was doing. The async methods
    // below stay actor-isolated; their generated completion-handler thunks hop onto the actor.
    public nonisolated static let shared = RadarIndoors()

    var currentModelId: String?

    /**
     RadarSDKIndoors calls
     */
    let sdk: RadarSDKIndoors?

    let onLocationUpdate: @Sendable @convention(block) (CLLocation) -> Void

    // Initialized entirely from nonisolated, Sendable expressions so the singleton can be built
    // off the actor. The stored properties are only read again from actor-isolated methods.
    nonisolated override init() {
        self.sdk = RadarSDKIndoors()
        self.onLocationUpdate = { location in
            Task {
                await RadarDelegateHolder.didUpdateClientLocation(location: location, stopped: false, source: .indoors)
                RadarLogger.shared.debug(
                    "Indoor location update | latitude = \(location.coordinate.latitude); longitude = \(location.coordinate.longitude); horizontalAccuracy = \(location.horizontalAccuracy); floor = \(location.floor.map { String($0.level) } ?? "nil"); timestamp = \(location.timestamp)"
                )
            }
        }
        super.init()
    }

    public func updateTracking(geofences: [RadarGeofence]?) async {
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
        if geofences?.contains(where: { $0.activeIndoorModelId != nil && ($0.activeIndoorModelId == currentModelId) }) == true {
            RadarLogger.shared.debug("model already in use")
            return
        }
        guard let modelId = geofences?.first(where: { $0.activeIndoorModelId != nil })?.activeIndoorModelId else {
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

    nonisolated public func getLocation(completionHandler: @escaping @Sendable (CLLocation?) -> Void) {
        Task { @RadarIndoorsActor in
            guard let sdk else {
                await MainActor.run { completionHandler(nil) }
                return
            }
            let location = RadarIndoors.validIndoorLocation(await sdk.getLocation())
            await MainActor.run { completionHandler(location) }
        }
    }

    // Returns the indoor location only when it carries a usable coordinate, so callers can gate on
    // `indoorLocation != nil` alone. CLLocationCoordinate2DIsValid accepts (0,0) ("null island"),
    // which is what a default/placeholder CLLocation reports, so also reject the origin — otherwise a
    // placeholder would overwrite the real device coordinate downstream.
    nonisolated static func validIndoorLocation(_ location: CLLocation?) -> CLLocation? {
        guard let location else {
            return nil
        }
        let coordinate = location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate),
            coordinate.latitude != 0.0 || coordinate.longitude != 0.0
        else {
            return nil
        }
        return location
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
