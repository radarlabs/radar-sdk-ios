//
//  RadarPing.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

@objc @objcMembers
@available(iOS 13.0, *)
internal final class RadarPing: NSObject, Sendable {
    
    public static let shared = RadarPing()
    
    // ping servers
    let urls = "https://dynamodb.us-east-1.amazonaws.com/ping,https://dynamodb.us-east-2.amazonaws.com/ping,https://dynamodb.us-west-1.amazonaws.com/ping,https://dynamodb.us-west-2.amazonaws.com/ping,https://dynamodb.ca-central-1.amazonaws.com/ping,https://dynamodb.ca-west-1.amazonaws.com/ping,https://dynamodb.eu-west-1.amazonaws.com/ping,https://dynamodb.eu-west-2.amazonaws.com/ping,https://dynamodb.eu-west-3.amazonaws.com/ping,https://dynamodb.eu-central-1.amazonaws.com/ping,https://dynamodb.eu-central-2.amazonaws.com/ping,https://dynamodb.eu-south-1.amazonaws.com/ping,https://dynamodb.eu-south-2.amazonaws.com/ping,https://dynamodb.eu-north-1.amazonaws.com/ping,https://dynamodb.il-central-1.amazonaws.com/ping,https://dynamodb.me-south-1.amazonaws.com/ping,https://streams.dynamodb.me-central-1.amazonaws.com/ping,https://dynamodb.af-south-1.amazonaws.com/ping,https://dynamodb.ap-east-1.amazonaws.com/ping,https://dynamodb.ap-east-2.amazonaws.com/ping,https://dynamodb.ap-southeast-3.amazonaws.com/ping,https://dynamodb.ap-south-1.amazonaws.com/ping,https://dynamodb.ap-south-2.amazonaws.com/ping,https://dynamodb.ap-northeast-3.amazonaws.com/ping,https://dynamodb.ap-northeast-2.amazonaws.com/ping,https://dynamodb.ap-southeast-1.amazonaws.com/ping,https://dynamodb.ap-southeast-2.amazonaws.com/ping,https://dynamodb.ap-southeast-4.amazonaws.com/ping,https://dynamodb.ap-northeast-1.amazonaws.com/ping,https://dynamodb.sa-east-1.amazonaws.com/ping,https://dynamodb.cn-north-1.amazonaws.com.cn/ping,https://dynamodb.cn-northwest-1.amazonaws.com.cn/ping,https://dynamodb.mx-central-1.amazonaws.com/ping,https://dynamodb.us-gov-east-1.amazonaws.com/ping,https://dynamodb.us-gov-west-1.amazonaws.com/ping".split(separator: ",")
    
    public func ping() async -> [String: Double] {
        let delays: [String: Double] = await withTaskGroup(of: (String, Double).self) { group in
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
            
            var results: [String: Double] = [:]
            for await (key, value) in group {
                results[key] = value
            }
            return results
        }
        return delays
    }
}
