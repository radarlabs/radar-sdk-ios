//
//  MapView.swift
//  Example
//
//  Created by ShiCheng Lu on 10/21/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapKit
import RadarSDK

fileprivate struct GeofenceOverlay: Identifiable {
    let id: String
    let coordinates: [CLLocationCoordinate2D]
}

private func circleCoordinates(center: CLLocationCoordinate2D, radius: Double, points: Int = 64) -> [CLLocationCoordinate2D] {
    (0..<points).map { i in
        let angle = 2 * Double.pi * Double(i) / Double(points)
        let dx = radius * cos(angle)
        let dy = radius * sin(angle)
        let deltaLat = dy / 111320.0
        let deltaLng = dx / (111320.0 * cos(center.latitude * .pi / 180))
        return CLLocationCoordinate2D(latitude: center.latitude + deltaLat, longitude: center.longitude + deltaLng)
    }
}

private func parseSyncedGeofences(from json: [String: Any]) -> [GeofenceOverlay] {
    guard let geofences = json["syncedGeofences"] as? [[String: Any]] else { return [] }
    return geofences.compactMap { gf in
        let gfId = gf["_id"] as? String ?? UUID().uuidString
        let type = (gf["type"] as? String ?? "").lowercased()
        
        if type == "polygon" || type == "isochrone" {
            guard let geometry = gf["geometry"] as? [String: Any],
                  let coordsArr = geometry["coordinates"] as? [[[Double]]],
                  let ring = coordsArr.first, !ring.isEmpty else { return nil }
            let coords = ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            return GeofenceOverlay(id: gfId, coordinates: coords)
        } else {
            guard let center = gf["geometryCenter"] as? [String: Any],
                  let coords = center["coordinates"] as? [Double], coords.count >= 2,
                  let radius = gf["geometryRadius"] as? Double, radius > 0 else { return nil }
            return GeofenceOverlay(id: gfId, coordinates: circleCoordinates(
                center: CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0]),
                radius: radius
            ))
        }
    }
}

private func parseSyncedPlaces(from json: [String: Any]) -> [CLLocationCoordinate2D] {
    guard let places = json["syncedPlaces"] as? [[String: Any]] else { return [] }
    return places.compactMap { place in
        guard let loc = place["location"] as? [String: Any],
              let coords = loc["coordinates"] as? [Double], coords.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }
}

private func parseSyncedBeacons(from json: [String: Any]) -> [CLLocationCoordinate2D] {
    guard let beacons = json["syncedBeacons"] as? [[String: Any]] else { return [] }
    return beacons.compactMap { beacon in
        guard let geo = beacon["geometry"] as? [String: Any],
              let coords = geo["coordinates"] as? [Double], coords.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    }
}

struct MapView: View {
    
//    @State var monitoringRegions: [CLCircularRegion] = []
    @State var syncRegion: CLCircularRegion?
    @State fileprivate var syncedGeofences: [GeofenceOverlay] = []
    @State var syncedPlaces: [CLLocationCoordinate2D] = []
    @State var syncedBeacons: [CLLocationCoordinate2D] = []
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                UserAnnotation()
                
//                ForEach(monitoringRegions, id: \.self) { region in
//                    let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
//                    MapCircle(center: region.center, radius: region.radius)
//                        .foregroundStyle(color.opacity(0.2))
//                        .stroke(color, lineWidth: 2)
//                }
                
                if let syncRegion {
                    MapCircle(center: syncRegion.center, radius: syncRegion.radius)
                        .foregroundStyle(Color.blue.opacity(0.06))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                }
                
                ForEach(syncedGeofences) { geofence in
                    MapPolygon(coordinates: geofence.coordinates)
                        .foregroundStyle(Color.purple.opacity(0.15))
                        .stroke(Color.purple, lineWidth: 1)
                }
                
                ForEach(Array(syncedPlaces.enumerated()), id: \.offset) { _, coord in
                    Annotation("", coordinate: coord) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
                
                ForEach(Array(syncedBeacons.enumerated()), id: \.offset) { _, coord in
                    Annotation("", coordinate: coord) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
            }
            .onReceive(timer) { _ in
//                monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
                syncRegion = RadarSyncManager.getSyncedRegion()
                if let json = RadarSyncManager.getSyncedStateJSON() {
                    syncedGeofences = parseSyncedGeofences(from: json)
                    syncedPlaces = parseSyncedPlaces(from: json)
                    syncedBeacons = parseSyncedBeacons(from: json)
                }
            }
        } else {
            Text("Map unavailable")
        }
    }
}

#Preview {
    MapView()
}
