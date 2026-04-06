//
//  RadarFileStorageTests.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Testing
@testable import RadarSDK

@Suite
struct RadarFileStorageTests {
    
    @Test func createFile() {
        let file = RadarFileStorage(fileName: "test/createTest.txt")
        #expect(file != nil, "file should exist after creation")
        guard let file else { return }
        
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        #expect(root != nil, "application support directory should exist")
        guard let root else { return }
        
        let path = root.appendingPathComponent("RadarSDK/test/createTest.txt")
        
        #expect(FileManager.default.fileExists(atPath: path.path), "file at path <application support>/RadarSDK/test/createFile.txt should exist")
        
        file.delete()
    }
    
    @Test func writeAndReadFile() throws {
        let file = RadarFileStorage(fileName: "test/writeAndReadTest.txt")
        #expect(file != nil, "file should exist after creation")
        guard let file else { return }
        
        
        let data = Data([2, 0, 1, 6, 0, 5, 2, 5])
        file.write(data: data)
        
        let readData1 = file.read()
        
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        #expect(root != nil, "application support directory should exist")
        guard let root else { return }
        let path = root.appendingPathComponent("RadarSDK/test/writeAndReadTest.txt")
        
        let readData2 = try? Data(contentsOf: path)
        
        #expect(data == readData1)
        #expect(data == readData2)
        
        file.delete()
    }
    
    @Test func appendFile() {
        let file = RadarFileStorage(fileName: "test/appendTest.txt")
        #expect(file != nil, "file should exist after creation")
        guard let file else { return }
        
        
        let data = Data([2, 0, 1, 6, 0, 5, 2, 5])
        file.write(data: data)
        
        let append = Data("HBD".map { UInt8($0.asciiValue!) })
        file.append(data: append)
        
        let expectedData = data + append
        
        let read = file.read()
        
        #expect(read == expectedData)
        
        file.delete()
    }
    
    @Test func writeOverWriteFile() {
        let file = RadarFileStorage(fileName: "test/writeOverWriteTest.txt")
        #expect(file != nil, "file should exist after creation")
        guard let file else { return }
        
        
        let data = Data([2, 0, 1, 6, 0, 5, 2, 5])
        file.write(data: data)
        
        let overwrite = Data("HBD".map { UInt8($0.asciiValue!) })
        file.write(data: overwrite)
        
        let read = file.read()
        
        #expect(read == overwrite)

        file.delete()
    }
}
