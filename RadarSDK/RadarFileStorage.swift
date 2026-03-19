//
//  RadarFileStorage.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

final class RadarFileStorage<T: Codable & Sendable>: @unchecked Sendable {
    
    private let fileURL: URL
    private let queue: DispatchQueue
    private var cache: T?
    private var cacheLoaded = false
    
    init(fileName: String) {
        self.queue = DispatchQueue(label: "io.radar.filestorage.\(fileName)", qos: .utility)
        
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("RadarSDK", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        
        var dirURL = dir
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dirURL.setResourceValues(values)
        
        self.fileURL = dir.appendingPathComponent(fileName)
    }
    
    
    func read() -> T? {
        queue.sync {
            if cacheLoaded { return cache }
            cacheLoaded = true
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            cache = try? JSONDecoder().decode(T.self, from: data)
            return cache
        }
    }
    
    func write(_ value: T) {
        queue.sync {
            cache = value
            cacheLoaded = true
            guard let data = try? JSONEncoder().encode(value) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    func writeAsync(_ value: T) {
        queue.async { [self] in
            cache = value
            cacheLoaded = true
            guard let data = try? JSONEncoder().encode(value) else { return }
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    func modify(_ transform: (inout T?) -> Void) {
        queue.sync {
            if !cacheLoaded {
                cacheLoaded = true
                if let data = try? Data(contentsOf: fileURL) {
                    cache = try? JSONDecoder().decode(T.self, from: data)
                }
            }
            transform(&cache)
            if let cache = cache, let data = try? JSONEncoder().encode(cache) {
                try? data.write(to: fileURL, options: .atomic)
            } else if cache == nil {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
    
    func clear() {
        queue.sync {
            cache = nil
            cacheLoaded = true
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
