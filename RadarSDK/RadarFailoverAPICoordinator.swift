//
//  RadarFailoverAPICoordinator.swift
//  RadarSDK
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

@objc(RadarFailoverAPICoordinator)
internal final class RadarFailoverAPICoordinator: NSObject {

    typealias HealthCheck = (_ primaryHost: String, _ completion: @escaping (Bool) -> Void) -> Void

    @objc(verifiedSharedInstance)
    nonisolated(unsafe) static let verifiedShared = RadarFailoverAPICoordinator(
        hostsProvider: { [RadarSettings.verifiedHost, RadarSettings.DefaultVerifiedHostSecondary] },
        logPrefix: "verified"
    )

    private let hostsProvider: () -> [String]
    private let healthCheck: HealthCheck
    private let healthInterval: TimeInterval
    private let schedulesHealthChecks: Bool
    private let healthQueue = DispatchQueue(label: "io.radar.failover.health")
    private let lock = NSLock()
    private let logPrefix: String

    private var usingSecondaryHost = false
    private var healthTimer: DispatchSourceTimer?
    private var healthCheckInFlight = false

    init(
        hostsProvider: @escaping () -> [String],
        healthInterval: TimeInterval = 15,
        schedulesHealthChecks: Bool = true,
        healthCheck: @escaping HealthCheck = RadarFailoverAPICoordinator.defaultHealthCheck,
        logPrefix: String = ""
    ) {
        self.hostsProvider = hostsProvider
        self.healthInterval = healthInterval
        self.schedulesHealthChecks = schedulesHealthChecks
        self.healthCheck = healthCheck
        self.logPrefix = logPrefix
        super.init()
    }

    @objc
    func request(
        path: String,
        performRequest: @escaping (_ url: String, _ completion: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void) -> Void,
        completionHandler: @escaping (RadarStatus, [AnyHashable: Any]?) -> Void
    ) {
        let selection = selectedHost()
        let url = Self.url(host: selection.host, path: path)

        RadarLogger.shared.debug("\(logTag): request host[\(selection.index)] path=\(path)")

        performRequest(url) { [weak self] status, res in
            self?.record(status: status, res: res, hostIndex: selection.index)
            completionHandler(status, res)
        }
    }

    @objc
    func reset() {
        let timer = locked {
            usingSecondaryHost = false
            healthCheckInFlight = false
            let timer = healthTimer
            healthTimer = nil
            return timer
        }
        timer?.cancel()
    }

    private func selectedHost() -> (index: Int, host: String) {
        let hosts = hostsProvider()
        let wantsSecondary = locked { usingSecondaryHost }
        let index = wantsSecondary && hosts.count > 1 ? 1 : 0
        let host = hosts.indices.contains(index) ? hosts[index] : RadarSettings.verifiedHost
        return (index, host)
    }

    private func record(status: RadarStatus, res: [AnyHashable: Any]?, hostIndex: Int) {
        guard hostIndex == 0 else {
            return
        }

        if Self.isRadarResponse(res) {
            return
        }

        if status == .errorNetwork || res == nil || !Self.isRadarResponse(res) {
            failoverToSecondary()
        }
    }

    private func failoverToSecondary() {
        let hosts = hostsProvider()
        guard hosts.count > 1 else {
            RadarLogger.shared.warning("\(logTag): primary failed, but no secondary verified host is configured")
            return
        }

        let shouldStartTimer = locked { () -> Bool in
            let shouldStart = !usingSecondaryHost && healthTimer == nil && schedulesHealthChecks
            usingSecondaryHost = true
            return shouldStart
        }

        RadarLogger.shared.info("\(logTag): primary verified host failed; switching future requests to secondary")

        if shouldStartTimer {
            startHealthTimer()
        }
    }

    private func startHealthTimer() {
        let timer = DispatchSource.makeTimerSource(queue: healthQueue)
        timer.schedule(deadline: .now() + healthInterval, repeating: healthInterval)
        timer.setEventHandler { [weak self] in
            self?.runHealthCheck()
        }

        let shouldResume = locked { () -> Bool in
            guard healthTimer == nil else {
                return false
            }
            healthTimer = timer
            return true
        }

        if shouldResume {
            timer.resume()
        } else {
            timer.cancel()
        }
    }

    private func runHealthCheck() {
        let primaryHost = selectedPrimaryHost()
        let shouldRun = locked { () -> Bool in
            guard usingSecondaryHost, !healthCheckInFlight else {
                return false
            }
            healthCheckInFlight = true
            return true
        }

        guard shouldRun else {
            return
        }

        healthCheck(primaryHost) { [weak self] healthy in
            self?.healthQueue.async {
                self?.finishHealthCheck(healthy: healthy)
            }
        }
    }

    private func finishHealthCheck(healthy: Bool) {
        locked {
            healthCheckInFlight = false
        }

        guard healthy else {
            RadarLogger.shared.debug("\(logTag): primary verified host health check failed; staying on secondary")
            return
        }

        let timer = locked { () -> DispatchSourceTimer? in
            usingSecondaryHost = false
            let timer = healthTimer
            healthTimer = nil
            return timer
        }
        timer?.cancel()
        RadarLogger.shared.info("\(logTag): primary verified host health check succeeded; returning to primary")
    }

    private func selectedPrimaryHost() -> String {
        let hosts = hostsProvider()
        return hosts.first ?? RadarSettings.verifiedHost
    }

    private var logTag: String {
        logPrefix.isEmpty ? "FailoverAPICoordinator" : "FailoverAPICoordinator[\(logPrefix)]"
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private static func isRadarResponse(_ res: [AnyHashable: Any]?) -> Bool {
        res?["meta"] != nil
    }

    private static func url(host: String, path: String) -> String {
        let combined = "\(host)\(path)"
        return combined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? combined
    }

    private static func defaultHealthCheck(primaryHost: String, completion: @escaping (Bool) -> Void) {
        let urlString = url(host: primaryHost, path: "/health")
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil, let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }

            completion((200..<300).contains(httpResponse.statusCode))
        }.resume()
    }
}
