//
//  RadarPing.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

@objc(RadarPing) @objcMembers
@available(iOS 13.0, *)
internal final class RadarPing: NSObject, Sendable {
    
    public static let shared = RadarPing()
    
    // ping servers    
    let urls = "https://dynamodb.us-east-1.amazonaws.com/ping,https://dynamodb.us-east-2.amazonaws.com/ping,https://dynamodb.us-west-1.amazonaws.com/ping,https://dynamodb.us-west-2.amazonaws.com/ping,https://dynamodb.ca-central-1.amazonaws.com/ping,https://dynamodb.ca-west-1.amazonaws.com/ping,https://dynamodb.eu-west-1.amazonaws.com/ping,https://dynamodb.eu-west-2.amazonaws.com/ping,https://dynamodb.eu-west-3.amazonaws.com/ping,https://dynamodb.eu-central-1.amazonaws.com/ping,https://dynamodb.eu-central-2.amazonaws.com/ping,https://dynamodb.eu-south-1.amazonaws.com/ping,https://dynamodb.eu-south-2.amazonaws.com/ping,https://dynamodb.eu-north-1.amazonaws.com/ping,https://dynamodb.il-central-1.amazonaws.com/ping,https://dynamodb.me-south-1.amazonaws.com/ping".split(separator: ",")

    public func ping() async -> [String: Int] {
        let delays: [String: Int] = await withTaskGroup(of: (String, Double).self) { group in
            for urlString in urls {
                guard let url = URL(string: String(urlString)) else {
                    continue
                }
                let request = URLRequest(url: url)
                group.addTask {
                    let start = Date() // now
                    let response = try? await URLSession.shared.data(for: request)
                    let end = Date() // now
                    return (
                        String(urlString),
                        response != nil ? end.timeIntervalSince(start) : .infinity
                    )
                }
            }
            
            var results: [String: Int] = [:]
            for await (key, value) in group {
                results[key.replacingOccurrences(of: "https://dynamodb.", with: "").replacingOccurrences(of: ".amazonaws.com/ping", with: "")] = Int(value * 1000)
            }
            return results
        }
        return delays
    }
    
    public func pingBlocking() -> [String: Int] {
        let semaphore = DispatchSemaphore(value: 0)

        var delays: [String: Int] = [:]
        Task {
            let delays = await ping()
            semaphore.signal()
        }
        
        semaphore.wait()
        return delays
    }
}
