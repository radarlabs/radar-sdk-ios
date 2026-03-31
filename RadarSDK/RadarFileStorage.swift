//
//  RadarFileStorage.swift
//  RadarSDK
//
//  Created by Alan Charles on 3/19/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

class RadarFileStorage {
    let file: URL
    let handle: FileHandle
    
    init?(fileName: String, directory: FileManager.SearchPathDirectory = .applicationSupportDirectory) {
        guard let documents = FileManager.default.urls(for: directory, in: .userDomainMask).first else {
            // failed to find directory
            return nil
        }
        let root = documents.appendingPathComponent("RadarSDK", isDirectory: true)
        var file = root.appendingPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: file.path) {
            let dir = file.deletingLastPathComponent()
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                // fail to create intermediate file
                return nil
            }
            
            FileManager.default.createFile(atPath: file.path, contents: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? file.setResourceValues(resourceValues)
        }
        self.file = file
        guard let handle = try? FileHandle(forWritingTo: file) else {
            // failed to create file handle
            return nil
        }
        self.handle = handle
    }
    
    func append(data: Data) {
        // TODO: replace with iOS 13.4 api handle?.seekToEnd()
        handle.seekToEndOfFile()
        handle.write(data)
    }
    
    func write(data: Data, options: Data.WritingOptions = []) {
        do {
            try data.write(to: file, options: options)
        } catch {
            
        }
    }
    
    func read() -> Data? {
        do {
            let data = try Data(contentsOf: file)
            return data
        } catch {
            print("Read failed")
            return nil
        }
    }
    
    func delete() {
        try? FileManager.default.removeItem(at: file)
    }
}

final class RadarFileStorageObject<T: Codable & Sendable>: @unchecked Sendable {
    
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
