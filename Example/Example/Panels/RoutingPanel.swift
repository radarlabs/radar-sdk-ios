//
//  RoutingPanel.swift
//  Example
//
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import SwiftUI

struct RoutingPanel: View {
    @EnvironmentObject var logStream: LogStream

    var body: some View {
        TogglePanel("Routing & Distance", initiallyExpanded: false) {
            ActionButton("getDistance (foot, bike, car)") {
                getDistance(label: "getDistance (foot, bike, car)", modes: [.foot, .bike, .car])
            }
            ActionButton("getDistance (car only)") {
                getDistance(label: "getDistance (car only)", modes: [.car])
            }
            ActionButton("getDistance (all modes)") {
                getDistance(
                    label: "getDistance (all modes)",
                    modes: [.foot, .bike, .car, .truck, .motorbike]
                )
            }
            ActionButton("getDistance (metric)") {
                getDistance(label: "getDistance (metric)", modes: [.foot, .car], units: .metric)
            }
            ActionButton("getDistance (from current location)") {
                Radar.getDistance(
                    destination: Self.destination,
                    modes: [.foot, .car],
                    units: .imperial
                ) { (status, routes) in
                    logRoutes(
                        "getDistance (from current location)",
                        status: status,
                        routes: routes,
                        requested: [.foot, .car]
                    )
                }
            }
            ActionButton("getMatrix") {
                getMatrix()
            }
        }
    }

    // MARK: - Actions

    private func getDistance(label: String, modes: RadarRouteMode, units: RadarRouteUnits = .imperial) {
        Radar.getDistance(
            origin: Self.origin,
            destination: Self.destination,
            modes: modes,
            units: units
        ) { (status, routes) in
            logRoutes(label, status: status, routes: routes, requested: modes)
        }
    }

    private func getMatrix() {
        let origins = [
            CLLocation(latitude: 40.78382, longitude: -73.97536),
            CLLocation(latitude: 40.70390, longitude: -73.98670),
        ]
        let destinations = [
            CLLocation(latitude: 40.64189, longitude: -73.78779),
            CLLocation(latitude: 35.99801, longitude: -78.94294),
        ]
        Radar.getMatrix(
            origins: origins,
            destinations: destinations,
            mode: .car,
            units: .imperial
        ) { (status, matrix) in
            let detail = """
                [0][0]: \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 0)?.duration.text))
                [0][1]: \(String(describing: matrix?.routeBetween(originIndex: 0, destinationIndex: 1)?.duration.text))
                [1][0]: \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 0)?.duration.text))
                [1][1]: \(String(describing: matrix?.routeBetween(originIndex: 1, destinationIndex: 1)?.duration.text))
                """
            logStream.write(
                status,
                summary: "getMatrix: \(Radar.stringForStatus(status))",
                detail: detail
            )
        }
    }

    // MARK: - Logging

    /// Logs every mode on `routes`, flags any mode whose presence doesn't match
    /// what was requested, and includes `dictionaryValue()` for comparison.
    private func logRoutes(
        _ label: String,
        status: RadarStatus,
        routes: RadarRoutes?,
        requested: RadarRouteMode
    ) {
        guard status == .success, let routes else {
            logStream.write(
                status,
                summary: "\(label): \(Radar.stringForStatus(status))",
                detail: "routes = \(String(describing: routes))"
            )
            return
        }

        let modes: [(name: String, mode: RadarRouteMode, route: RadarRoute?)] = [
            ("foot", .foot, routes.foot),
            ("bike", .bike, routes.bike),
            ("car", .car, routes.car),
            ("truck", .truck, routes.truck),
            ("motorbike", .motorbike, routes.motorbike),
        ]

        var lines = ["geodesic: \(routes.geodesic?.text ?? "nil")"]
        var mismatches: [String] = []
        if routes.geodesic == nil {
            mismatches.append("geodesic missing")
        }
        for (name, mode, route) in modes {
            let wanted = requested.contains(mode)
            if let route {
                lines.append("\(name): \(route.distance.text), \(route.duration.text)")
            } else {
                lines.append("\(name): nil")
            }
            if wanted && route == nil {
                mismatches.append("\(name) requested but nil")
            } else if !wanted && route != nil {
                mismatches.append("\(name) not requested but present")
            }
        }

        let dictionary = routes.dictionaryValue()
        let dictionaryKeys = dictionary.keys.map { "\($0)" }.sorted()
        lines.append("")
        lines.append("dictionaryValue keys: \(dictionaryKeys.joined(separator: ", "))")
        lines.append("dictionaryValue = \(dictionary)")

        if mismatches.isEmpty {
            logStream.write(result: "\(label): OK", detail: lines.joined(separator: "\n"))
        } else {
            lines.insert("MISMATCH: \(mismatches.joined(separator: "; "))\n", at: 0)
            logStream.write(error: "\(label): mismatch", detail: lines.joined(separator: "\n"))
        }
    }

    // MARK: - Constants

    private static let origin = CLLocation(latitude: 40.78382, longitude: -73.97536)
    private static let destination = CLLocation(latitude: 40.70390, longitude: -73.98670)
}

#Preview {
    ScrollView {
        RoutingPanel().padding()
    }
    .environmentObject(LogStream())
}
