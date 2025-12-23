//
//  RadarPing.swift
//  RadarSDK
//
//  Created by ShiCheng Lu on 12/16/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

private final class LockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T?

    func set(_ value: T) {
        lock.lock(); defer { lock.unlock() }
        _value = value
    }

    func get() -> T? {
        lock.lock(); defer { lock.unlock() }
        return _value
    }
}

@objc(RadarPing) @objcMembers
@available(iOS 13.0, *)
internal final class RadarPing: NSObject, Sendable {
    
    public static let shared = RadarPing()
    
    struct PingServer {
        let id: String
        let url: URL
        let location: CLLocation
    }
    
    let MAX_SERVERS: Int = 3;
    
    // ping servers
    let pingServers: [PingServer] = [
        .init(id: "us-east-1", url: URL(string: "https://dynamodb.us-east-1.amazonaws.com/ping")!, location: .init(latitude: 39.03947448730469, longitude: -77.49180603027344)),
        .init(id: "us-east-2", url: URL(string: "https://dynamodb.us-east-2.amazonaws.com/ping")!, location: .init(latitude: 39.961181640625, longitude: -82.99878692626953)),
        .init(id: "us-west-1", url: URL(string: "https://dynamodb.us-west-1.amazonaws.com/ping")!, location: .init(latitude: 37.77492904663086, longitude: -122.41941833496094)),
        .init(id: "us-west-2", url: URL(string: "https://dynamodb.us-west-2.amazonaws.com/ping")!, location: .init(latitude: 45.5234489440918, longitude: -122.67620849609375)),
        .init(id: "ca-central-1", url: URL(string: "https://dynamodb.ca-central-1.amazonaws.com/ping")!, location: .init(latitude: 45.50883865356445, longitude: -73.58780670166016)),
        .init(id: "ca-west-1", url: URL(string: "https://dynamodb.ca-west-1.amazonaws.com/ping")!, location: .init(latitude: 51.05010986328125, longitude: -114.08528900146484)),
        .init(id: "eu-west-1", url: URL(string: "https://dynamodb.eu-west-1.amazonaws.com/ping")!, location: .init(latitude: 53.343990325927734, longitude: -6.267189979553223)),
        .init(id: "eu-west-2", url: URL(string: "https://dynamodb.eu-west-2.amazonaws.com/ping")!, location: .init(latitude: 51.50852966308594, longitude: -0.12574000656604767)),
        .init(id: "eu-west-3", url: URL(string: "https://dynamodb.eu-west-3.amazonaws.com/ping")!, location: .init(latitude: 48.85836410522461, longitude: 2.294532060623169)),
        .init(id: "eu-central-1", url: URL(string: "https://dynamodb.eu-central-1.amazonaws.com/ping")!, location: .init(latitude: 50.11088180541992, longitude: 8.68199634552002)),
        .init(id: "eu-central-2", url: URL(string: "https://dynamodb.eu-central-2.amazonaws.com/ping")!, location: .init(latitude: 47.366668701171875, longitude: 8.550000190734863)),
        .init(id: "eu-south-1", url: URL(string: "https://dynamodb.eu-south-1.amazonaws.com/ping")!, location: .init(latitude: 45.464271545410156, longitude: 9.189510345458984)),
        .init(id: "eu-south-2", url: URL(string: "https://dynamodb.eu-south-2.amazonaws.com/ping")!, location: .init(latitude: 40.41695022583008, longitude: -3.683866024017334)),
        .init(id: "eu-north-1", url: URL(string: "https://dynamodb.eu-north-1.amazonaws.com/ping")!, location: .init(latitude: 59.33258056640625, longitude: 18.064899444580078)),
        .init(id: "il-central-1", url: URL(string: "https://dynamodb.il-central-1.amazonaws.com/ping")!, location: .init(latitude: 47.627498626708984, longitude: -122.34619903564453)),
        .init(id: "me-south-1", url: URL(string: "https://dynamodb.me-south-1.amazonaws.com/ping")!, location: .init(latitude: 26.215360641479492, longitude: 50.58319854736328)),
        .init(id: "me-central-1", url: URL(string: "https://streams.dynamodb.me-central-1.amazonaws.com/ping")!, location: .init(latitude: 26.215360641479492, longitude: 50.58319854736328)),
        .init(id: "af-south-1", url: URL(string: "https://dynamodb.af-south-1.amazonaws.com/ping")!, location: .init(latitude: -33.925838470458984, longitude: 18.423219680786133)),
        .init(id: "ap-east-1", url: URL(string: "https://dynamodb.ap-east-1.amazonaws.com/ping")!, location: .init(latitude: 22.285520553588867, longitude: 114.1576919555664)),
        .init(id: "ap-east-2", url: URL(string: "https://dynamodb.ap-east-2.amazonaws.com/ping")!, location: .init(latitude: 47.627498626708984, longitude: -122.34619903564453)),
        .init(id: "ap-southeast-3", url: URL(string: "https://dynamodb.ap-southeast-3.amazonaws.com/ping")!, location: .init(latitude: -6.208677768707275, longitude: 106.84548950195312)),
        .init(id: "ap-south-1", url: URL(string: "https://dynamodb.ap-south-1.amazonaws.com/ping")!, location: .init(latitude: 19.07597541809082, longitude: 72.87738037109375)),
        .init(id: "ap-south-2", url: URL(string: "https://dynamodb.ap-south-2.amazonaws.com/ping")!, location: .init(latitude: 17.375280380249023, longitude: 78.47444152832031)),
        .init(id: "ap-northeast-3", url: URL(string: "https://dynamodb.ap-northeast-3.amazonaws.com/ping")!, location: .init(latitude: 34.69388961791992, longitude: 135.50221252441406)),
        .init(id: "ap-northeast-2", url: URL(string: "https://dynamodb.ap-northeast-2.amazonaws.com/ping")!, location: .init(latitude: 37.56631088256836, longitude: 126.97794342041016)),
        .init(id: "ap-southeast-1", url: URL(string: "https://dynamodb.ap-southeast-1.amazonaws.com/ping")!, location: .init(latitude: 1.2896699905395508, longitude: 103.85006713867188)),
        .init(id: "ap-southeast-2", url: URL(string: "https://dynamodb.ap-southeast-2.amazonaws.com/ping")!, location: .init(latitude: -33.86785125732422, longitude: 151.2073211669922)),
        .init(id: "ap-southeast-4", url: URL(string: "https://dynamodb.ap-southeast-4.amazonaws.com/ping")!, location: .init(latitude: -37.81399917602539, longitude: 144.96331787109375)),
        .init(id: "ap-northeast-1", url: URL(string: "https://dynamodb.ap-northeast-1.amazonaws.com/ping")!, location: .init(latitude: 35.68950653076172, longitude: 139.6916961669922)),
        .init(id: "sa-east-1", url: URL(string: "https://dynamodb.sa-east-1.amazonaws.com/ping")!, location: .init(latitude: -23.547435760498047, longitude: -46.63739776611328)),
        .init(id: "cn-north-1", url: URL(string: "https://dynamodb.cn-north-1.amazonaws.com.cn/ping")!, location: .init(latitude: 39.907501220703125, longitude: 116.39723205566406)),
        .init(id: "cn-northwest-1", url: URL(string: "https://dynamodb.cn-northwest-1.amazonaws.com.cn/ping")!, location: .init(latitude: 37.5099983215332, longitude: 105.18000030517578)),
        .init(id: "mx-central-1", url: URL(string: "https://dynamodb.mx-central-1.amazonaws.com/ping")!, location: .init(latitude: 47.627498626708984, longitude: -122.34619903564453)),
        .init(id: "us-gov-east-1", url: URL(string: "https://dynamodb.us-gov-east-1.amazonaws.com/ping")!, location: .init(latitude: 40.0992317199707, longitude: -83.11408233642578)),
        .init(id: "us-gov-west-1", url: URL(string: "https://dynamodb.us-gov-west-1.amazonaws.com/ping")!, location: .init(latitude: 47.627498626708984, longitude: -122.34619903564453)),
    ]

    public func ping(location: CLLocation) async -> [String: Int] {
        let closestPingServers = pingServers.sorted{$0.location.distance(from: location) < $1.location.distance(from: location)}
            .prefix(MAX_SERVERS)
            .map{$0}
        let delays: [String: Int] = await withTaskGroup(of: (PingServer, Double).self) { group in
            for pingServer in closestPingServers {
                let request = URLRequest(url: pingServer.url)
                group.addTask {
                    let start = Date() // now
                    let response = try? await URLSession.shared.data(for: request)
                    let end = Date() // now
                    return (
                        pingServer,
                        response != nil ? end.timeIntervalSince(start) : .infinity
                    )
                }
            }
            
            var results: [String: Int] = [:]
            for await (key, value) in group {
                results[key.id] = Int(value * 1000)
            }
            return results
        }
        return delays
    }
    
    public func pingBlocking(location: CLLocation) -> [String: Int] {
        let semaphore = DispatchSemaphore(value: 0)
        // TODO: DO NOT USE THIS DO IT PROPERLY
        let box = LockedBox<[String: Int]>()
        Task {
            await ping(location: location) // Prefetch to warm cache
            box.set(await ping(location: location))
            semaphore.signal()
        }
        
        semaphore.wait()
        let delays = box.get() ?? [:]
        return delays
    }
}
