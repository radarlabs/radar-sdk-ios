import SwiftUI
import MapKit
import RadarSDK

struct MapView: View {
    
    @State var monitoringRegions: [CLCircularRegion] = []
    @State var syncedRegion: CLCircularRegion?
    @State var syncedGeofences: [RadarGeofence] = []
    @State var syncedPlaces: [RadarPlace] = []
    @State var syncedBeacons: [RadarBeacon] = []
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                UserAnnotation()
                
                // Existing client geofence monitoring regions
                ForEach(monitoringRegions, id: \.self) { region in
                    let color = region.identifier.contains("bubble") ? Color.blue : Color.orange
                    MapCircle(center: region.center, radius: region.radius)
                        .foregroundStyle(color.opacity(0.2))
                        .stroke(color, lineWidth: 2)
                }
                
                // Synced region (green)
                if let syncedRegion {
                    MapCircle(center: syncedRegion.center, radius: syncedRegion.radius)
                        .foregroundStyle(Color.green.opacity(0.1))
                        .stroke(Color.green, lineWidth: 3)
                }
                
                // Synced geofences (red for circles)
                ForEach(syncedGeofences, id: \._id) { geofence in
                    if let circle = geofence.geometry as? RadarCircleGeometry {
                        MapCircle(center: circle.center.coordinate, radius: circle.radius)
                            .foregroundStyle(Color.red.opacity(0.2))
                            .stroke(Color.red, lineWidth: 2)
                    } else if let polygon = geofence.geometry as? RadarPolygonGeometry,
                              let coords = polygon._coordinates, !coords.isEmpty {
                        MapPolygon(coordinates: coords.map { $0.coordinate })
                            .foregroundStyle(Color.red.opacity(0.2))
                            .stroke(Color.red, lineWidth: 2)
                    }
                }
                
                // Synced places (purple pins)
                ForEach(syncedPlaces, id: \._id) { place in
                    Annotation(place.name, coordinate: place.location.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.purple)
                    }
                }
                
                // Synced beacons (teal pins)
                ForEach(syncedBeacons, id: \._id) { beacon in
                    if let geometry = beacon.geometry {
                        Annotation(beacon.tag ?? "beacon", coordinate: geometry.coordinate) {
                            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                                .foregroundStyle(.teal)
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                monitoringRegions = Array(CLLocationManager().monitoredRegions) as? [CLCircularRegion] ?? []
                syncedRegion = RadarSyncManager.getSyncedRegion() ?? nil
                syncedGeofences = RadarSyncManager.getSyncedGeofences()
                syncedPlaces = RadarSyncManager.getSyncedPlaces()
                syncedBeacons = RadarSyncManager.getSyncedBeacons()
            }
        } else {
            Text("Map unavailable")
        }
    }
}
