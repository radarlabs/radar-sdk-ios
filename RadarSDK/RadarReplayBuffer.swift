//
//  RadarReplayBuffer.swift
//  RadarSDK
//
//  Created by Alan Charles on 6/29/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarReplayBuffer)
final class RadarReplayBuffer: NSObject, @unchecked Sendable {
    
    private static let maxBufferSize = 120 // one hour of updates
    private static let storageKey = "radar-replays"
    
    var mutableReplayBuffer: [RadarReplay] = []
    private var isFlushing = false
    private var batchFlushTimer: Timer?
    
    @objc(sharedInstance)
    static let sharedInstance = RadarReplayBuffer()
    
    private override init() {
        super.init()
    }
    
    @objc
    var flushableReplays: [RadarReplay] {
        return mutableReplayBuffer
    }
    
    @objc(writeNewReplayToBuffer:)
    func writeNewReplayToBuffer(_ replayParams: [AnyHashable: Any]) {
        if mutableReplayBuffer.count >= Self.maxBufferSize {
            dropOldestReplay()
        }
        
        let radarReplay = RadarReplay(params: replayParams)
        mutableReplayBuffer.append(radarReplay)
        
        guard let sdkConfiguration = RadarSettings.sdkConfiguration, sdkConfiguration.usePersistence else {
            return
        }
        
        // if buffer length is above 50, remove every fifth replay from the persisted buffer
        let bufferToPersist: [RadarReplay]
        if mutableReplayBuffer.count > 50 {
            bufferToPersist = mutableReplayBuffer.enumerated()
                .filter { ($0.offset + 1) % 5 != 0 }
                .map { $0.element }
        } else {
            bufferToPersist = mutableReplayBuffer
        }
        
        do {
            let replaysData = try NSKeyedArchiver.archivedData(withRootObject: bufferToPersist, requiringSecureCoding: true)
            UserDefaults.standard.set(replaysData, forKey: Self.storageKey)
        } catch {
            RadarLogger.shared.debug("Error archiving replays")
        }
    }
    
    @objc(flushReplaysWithCompletionHandler:completionHandler:)
    func flushReplays(withCompletionHandler replayParams: [AnyHashable: Any]?, completionHandler: RadarFlushReplaysCompletionHandler?) {
        if isFlushing {
            RadarLogger.shared.debug("Already flushing replays")
            completionHandler?(.errorServer, nil)
            return
        }
        
        isFlushing = true
        
        let replaysArray = flushableReplays
        if replaysArray.isEmpty && replayParams == nil {
            RadarLogger.shared.debug("No replays to flush")
            isFlushing = false
            completionHandler?(.success, nil)
            return
        }
        
        var replaysRequestArray = replaysArray.map { $0.replayParams }
        
        // if we have a current track update, add it to the local replay list
        var newReplayParams: [AnyHashable: Any]?
        if let replayParams = replayParams {
            var params = replayParams
            params["replayed"] = true
            params["updatedAtMs"] = Int(Date().timeIntervalSince1970 * 1000)
            // rely on updatedAtMs for replays, not updatedAtMsDiff
            params.removeValue(forKey: "updatedAtMsDiff")
            newReplayParams = params
            replaysRequestArray.append(params)
        }
        
        RadarLogger.shared.debug("Flushing \(replaysRequestArray.count) replays")
        
        guard let bridge = RadarSwift.bridge else {
            isFlushing = false
            completionHandler?(.errorServer, nil)
            return
        }
        
        bridge.flushReplaysRequest(replaysRequestArray) { [self] status, res in
            if status == .success {
                RadarLogger.shared.debug("Flushed replays successfully")
                removeReplaysFromBuffer(replaysArray)
                RadarLogger.flushLogs()
            } else if replayParams != nil, let newReplayParams = newReplayParams {
                writeNewReplayToBuffer(newReplayParams)
            }
            
            setIsFlushing(false)
            completionHandler?(status, res)
        }
    }
    
    @objc(setIsFlushing:)
    func setIsFlushing(_ flushing: Bool) {
        isFlushing = flushing
    }
    
    @objc
    func clearBuffer() {
        mutableReplayBuffer.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
    
    private func removeReplaysFromBuffer(_ replays: [RadarReplay]) {
        mutableReplayBuffer.removeAll { replay in replays.contains { $0.isEqual(replay) } }
        
        do {
            let replaysData = try NSKeyedArchiver.archivedData(withRootObject: mutableReplayBuffer, requiringSecureCoding: true)
            UserDefaults.standard.set(replaysData, forKey: Self.storageKey)
        } catch {
            RadarLogger.shared.debug("Error archiving replays")
        }
    }
    
    @objc
    func loadReplaysFromPersistentStore() {
        guard let replaysData = UserDefaults.standard.object(forKey: Self.storageKey) as? Data else {
            return
        }
        
        let allowedClasses: [AnyClass] = [NSArray.self, RadarReplay.self, NSDictionary.self, NSString.self, NSNumber.self]
        do {
            let replays = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: replaysData) as? [RadarReplay]
            RadarLogger.shared.debug("Loaded replays | length = \(replays?.count ?? 0)")
            if let replays = replays {
                mutableReplayBuffer = replays
            }
        } catch {
            RadarLogger.shared.debug("Error unarchiving replays")
        }
    }
    
    @objc
    func dropOldestReplay() {
        if !mutableReplayBuffer.isEmpty {
            mutableReplayBuffer.removeFirst()
        }
    }
    
    // MARK: - Batch Methods
    
    @objc(addToBatch:options:)
    func addToBatch(_ params: [AnyHashable: Any], options: RadarTrackingOptions) {
        var batchParams = params
        batchParams["replayed"] = true
        batchParams["updatedAtMs"] = Int(Date().timeIntervalSince1970 * 1000)
        batchParams.removeValue(forKey: "updatedAtMsDiff")
        
        writeNewReplayToBuffer(batchParams)
        
        if options.batchInterval > 0 && batchFlushTimer == nil {
            scheduleBatchTimer(withInterval: options.batchInterval)
        }
        
        RadarLogger.shared.debug("Added to batch | size = \(mutableReplayBuffer.count)")
    }
    
    @objc(shouldFlushBatchWithOptions:)
    func shouldFlushBatch(withOptions options: RadarTrackingOptions) -> Bool {
        if mutableReplayBuffer.isEmpty {
            return false
        }
        
        if options.batchSize > 0 && mutableReplayBuffer.count >= Int(options.batchSize) {
            RadarLogger.shared.debug("Batch size limit reached")
            return true
        }
        
        return false
    }
    
    @objc(scheduleBatchTimerWithInterval:)
    func scheduleBatchTimer(withInterval interval: Int32) {
        DispatchQueue.main.async {
            if let timer = self.batchFlushTimer {
                timer.invalidate()
                self.batchFlushTimer = nil
            }
            
            RadarLogger.shared.debug("Scheduling batch timer | interval = \(interval)")
            
            self.batchFlushTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false) { _ in
                RadarLogger.shared.debug("Batch timer fired")
                self.batchFlushTimer = nil
                self.flushBatch()
            }
        }
    }
    
    @objc
    func cancelBatchTimer() {
        let cancelTimerBlock = {
            if let timer = self.batchFlushTimer {
                RadarLogger.shared.debug("Canceling batch timer")
                timer.invalidate()
                self.batchFlushTimer = nil
            }
        }
        
        if Thread.isMainThread {
            cancelTimerBlock()
        } else {
            DispatchQueue.main.sync(execute: cancelTimerBlock)
        }
    }
    
    @objc
    func flushBatch() {
        if isFlushing {
            RadarLogger.shared.debug("Skipping batch flush; already flushing replays")
            return
        }
        cancelBatchTimer()
        flushReplays(withCompletionHandler: nil, completionHandler: nil)
    }
    
    @objc
    func batchCount() -> UInt {
        return UInt(mutableReplayBuffer.count)
    }
}
