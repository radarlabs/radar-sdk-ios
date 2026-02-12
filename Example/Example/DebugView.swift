//
//  DebugView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import CoreML
import RadarSDKIndoors
import CoreLocation
import MapLibre
import ARKit
import CoreMotion
import Combine
import Gzip
import RadarSDK

class DebugViewModel: NSObject, ObservableObject {
    @Published var transform = simd_float4x4()
    @Published var heading = 0.0
    
    var updated: () -> Void = {}
    
    // Internal tracking
    var session: ARSession = ARSession()
    var startPosition: simd_float3?
    
    override init() {
        super.init()
        
        session.delegate = self
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func resetTracking() {
        startPosition = nil
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}
    
extension DebugViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        transform = frame.camera.transform
        updated()
    }
}

extension DebugViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading.trueHeading
    }
}

extension RadarSite {
    func toXY(_ coords: CLLocationCoordinate2D) -> (Double, Double) {
        let rel_lat = coords.latitude - geometry.coordinates[1]
        let rel_lng = coords.longitude - geometry.coordinates[0]
        
        return (rel_lng * cos(geometry.coordinates[1] * .pi / 180.0) * 111320, rel_lat * 111132)
    }
    
    func fromXY(_ xy: (Double, Double)) -> CLLocationCoordinate2D {
        let (x, y) = xy
        let rel_lat = y / 111132.0
        let rel_lng = x / (cos(geometry.coordinates[1] * .pi / 180.0) * 111320.0)
        
        return CLLocationCoordinate2D(latitude: rel_lat + geometry.coordinates[1], longitude: rel_lng + geometry.coordinates[0])
    }
}

func circleFor(site: RadarSite, x: Double, y: Double, r: Double, c: Int = 8) -> [CLLocationCoordinate2D] {
    var coordinates: [CLLocationCoordinate2D] = []
    for i in 0...c {
        let angle = 2.0 * Double.pi * Double(i) / Double(c)
        let dx = r * cos(angle)
        let dy = r * sin(angle)

        coordinates.append(site.fromXY((x + dx, y + dy)))
    }
    // close ring
    return coordinates
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return formatter
}()

extension CLBeacon {
    @available(iOS 13.0, *)
    func toDictionary() -> [String: Any] {
        [
            "uuid": uuid.uuidString,
            "major": major,
            "minor": minor,
            "rssi": rssi
        ]
    }
}

struct DebugView: View {
    
    let radarDelegateState: RadarDelegateState
    
    @State
    var image: UIImage? = nil
    
    @State
    var ranged = false
    
    @State
    var success = false
    
    let site: RadarSite? = {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let siteResponse = try decoder.decode(RadarSiteResponse.self, from: Data(siteString.utf8))
            return siteResponse.site
        } catch {
            return nil
        }
    }()
    
    @State
    var mapStyle: MLNStyle? = nil
    
    @State
    var calibration: (Double, Double) = (0, 0)
    
    @State
    var rotation: Double = 0
    
    @State
    var surveying = false
    
    @StateObject private var viewModel = DebugViewModel()
    
    @AppStorage("radar-prediction-average-window") var predictionAverageWindow: Int = 1
    @AppStorage("radar-measurement-drop-filter") var measurementDropFilter: Int = 0
    @AppStorage("radar-calibration-mode") var calibrationMode: Bool = false
    @AppStorage("radar-kalman-filter") var kalmanFilter: Bool = true
    @AppStorage("radar-raw-prediction") var rawPrediction: Bool = false
    @AppStorage("radar-prediction-confidence") var predictionConfidence: Bool = false

    let scanner = RadarIndoorScan(uuids: [
        "160C2FE2-0FA8-4A03-B31B-D772318C12F5",
        "DEB7A751-58E9-470C-B02F-E0A0E0CB131D",
    ])
//    let model = RadarBeaconRSSIModel()
    
    @State
    var collectedData: [SurveyData] = []
    @State
    var collectedBeaconList = Set<String>()
    
    @State
    var tapCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State
    var arCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State
    var predCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State
    var lastPredCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State
    var displayPredCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    func updatePoints(style: MLNStyle?) {
        if let source = style?.source(withIdentifier: "points-src"),
           let shape = source as? MLNShapeSource {
            shape.shape = MLNShapeCollectionFeature(shapes: [
                MLNPointFeature(coordinate: tapCoord) { f in
                    f.attributes["color"] = "#00FF00"
                },
                MLNPointFeature(coordinate: arCoord) { f in
                    f.attributes["color"] = "#FF00FF"
                },
                MLNPointFeature(coordinate: displayPredCoord) { f in
                    f.attributes["color"] = "#0000FF"
                },
//                MLNPointFeature(coordinate: predCoord) { f in
//                    f.attributes["color"] = "#00FFFF"
//                },
//                MLNPointFeature(coordinate: lastPredCoord) { f in
//                    f.attributes["color"] = "#FF0000"
//                },
            ])
        }
    }
    
    let locationManager = CLLocationManager()
    
    @State var lastUpdatedAt = Date.distantPast;
    @State var timer: AnyCancellable? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            MyMapView(withRadar: "prj_test_pk_cb81bb9205567e2c454f14ae17db6290bcd2e27e")
                .onLoaded { mapView in
                    if let center = site?.fromXY((0, 0)) {
                        mapView.setCenter(
                            CLLocationCoordinate2D(
                                latitude: center.latitude,
                                longitude: center.longitude
                            ), zoomLevel: 15, animated: false)
                    }
                }
                .onStyleLoaded { style in
                    guard let site else {
                        return
                    }
                    mapStyle = style
                    let coords = site.floorplan.geometry.coordinates
                    let coordinates = MLNCoordinateQuad(
                        topLeft:     CLLocationCoordinate2D(latitude: coords[0][0][1], longitude: coords[0][0][0]),
                        bottomLeft:  CLLocationCoordinate2D(latitude: coords[0][3][1], longitude: coords[0][3][0]),
                        bottomRight: CLLocationCoordinate2D(latitude: coords[0][2][1], longitude: coords[0][2][0]),
                        topRight:    CLLocationCoordinate2D(latitude: coords[0][1][1], longitude: coords[0][1][0]),
                    )
                    let imageSource = MLNImageSource(
                        identifier: "overlay‑src",
                        coordinateQuad: coordinates,
                        url: URL(string: "https://api.radar-staging.com/api/v1/assets/\(site.floorplan.path)")!
                    )
                    style.addSource(imageSource)
                    let rasterLayer = MLNRasterStyleLayer(identifier: "overlay‑layer", source: imageSource)
                    style.addLayer(rasterLayer)
                    
                    let pointsSource = MLNShapeSource(identifier: "points-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(pointsSource)
                    let pointsLayer = MLNCircleStyleLayer(identifier: "points-layer", source: pointsSource)
//                    pointsLayer.circleRadius = NSExpression(forConstantValue: 5)
                    pointsLayer.circleColor = NSExpression(forKeyPath: "color")
                    style.addLayer(pointsLayer)
                    
                    let coverageSource = MLNShapeSource(identifier: "coverage-src", shape: MLNMultiPolygonFeature(polygons: []))
                    style.addSource(coverageSource)
                    let coverageLayer = MLNFillStyleLayer(identifier: "coverage-layer", source: coverageSource)
                    coverageLayer.fillOpacity = NSExpression(forConstantValue: 0.3)
                    style.addLayer(coverageLayer)
                }
                .onTapMapGesture { value in
                    tapCoord = value.coordinate
                    updatePoints(style: value.mapView.style)
                }.frame(height: calibrationMode ? 400 : 1000)
            
            if (calibrationMode) {
                HStack {
                    ARViewContainer(viewModel: viewModel).frame(width: 200)
                    Spacer()
                    GeometryReader { geo in
                        Slider(value: $rotation, in: -Double.pi...Double.pi)
                            .rotationEffect(.degrees(90), anchor: .topLeading)
                            .frame(width: geo.size.height)
                            .offset(x: 30)
                    }
                    Spacer()
                    VStack {
                        if let xy = site?.toXY(tapCoord) {
                            Text(String(format: "%.1f, %.1f", xy.0, xy.1))
                        }
                        
                        let xyz = viewModel.transform.columns.3
                        Text(String(format: "%.1f, %.1f, %.1f", xyz.x, xyz.y, xyz.z))
                        
                        HStack {
                            Circle()
                                .fill((ranged) ? Color.green : Color.gray)
                                .frame(width: 20, height: 20)
                            Circle()
                                .fill((success) ? Color.green : Color.gray)
                                .frame(width: 20, height: 20)
                        }
                        
                        HStack {
                            Button(action: {
                                viewModel.resetTracking()
                                if let calib = site?.toXY(tapCoord) {
                                    calibration = calib
                                }
                            }) {
                                Text("Calibrate")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                surveying = !surveying
                                if surveying {
                                    scanner.start()
                                } else {
                                    scanner.stop()
                                }
                            }) {
                                Text(surveying ? "Stop" : "Start")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(surveying ? Color.red : Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        HStack {
                            Button(action: {
                                if collectedData.isEmpty {
                                    return
                                }
                                
                                // convert collected data into csv
                                let beacons = collectedBeaconList.sorted()
                                // header
                                var csv = (["timestamp", "x", "y"] + beacons).joined(separator: ",") + "\n"
                                for data in collectedData {
                                    csv.append("\(data.timestamp),\(data.x),\(data.y),")
                                    csv.append(beacons.map { "\(data.rssi[$0] ?? 0)" }.joined(separator: ","))
                                    csv.append("\n")
                                }
                                
                                guard let data = csv.data(using: .utf8) else {
                                    print("invalid conversion to Data")
                                    return
                                }
                                guard let compressed = try? data.gzipped(level: .bestCompression) else {
                                    print("unable to compress")
                                    return
                                }
                                Task {
                                    await SurveyApi.createSurvey(data: compressed)
                                }
                                
                                collectedBeaconList.removeAll()
                                collectedData.removeAll()
                            }) {
                                Text("Send data")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(collectedData.isEmpty ? Color.gray : Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        
                    }.frame(width: 200)
                }
            }
        }.onAppear {
            Task {
                scanner.update = { beacons in
                    guard let location = site?.toXY(arCoord),
                          let date = dateFormatter.string(for: Date.now) else {
                        return;
                    }
                    
                    var rssi = [String: Int]()
                    beacons.forEach { beacon in
                        let id = "\(beacon.major)_\(beacon.minor)"
                        rssi[id] = beacon.rssi
                        collectedBeaconList.insert(id)
                    }
                    let data = SurveyData(
                        timestamp: date,
                        x: location.0,
                        y: location.1,
                        rssi: rssi
                    )
                    
                    if surveying {
                        collectedData.append(data)
                    }
                    
                    if let source = mapStyle?.source(withIdentifier: "coverage-src"),
                       let shape = source as? MLNShapeSource {
                        let polygons = collectedData.compactMap { data in
                            let coords = circleFor(site: site!, x: data.x, y: data.y, r: 0.5)
                            return MLNPolygonFeature(coordinates: coords, count: UInt(coords.count))
                        }
                        shape.shape = MLNShapeCollectionFeature(shapes: polygons)
                    }
                }
                
                // update 20 times a second
                timer = Timer.publish(every: 0.05, on: .main, in: .common)
                    .autoconnect()
                    .sink { _ in
                    // linear interpolation based on time to next location (1s)
                        let now = Date.now
                        let timeToNextUpdate = max(1 - now.timeIntervalSince(lastUpdatedAt), 0)
                        let lerp = min(timeToNextUpdate, 1)
                        let latitude = lastPredCoord.latitude * lerp + predCoord.latitude * (1 - lerp)
                        let longitude = lastPredCoord.longitude * lerp + predCoord.longitude * (1 - lerp)
                        displayPredCoord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        
                        let coord = radarDelegateState.clientLocation?.coordinate
                        if coord != nil && coord != predCoord {
                            lastPredCoord = predCoord
                            predCoord = coord!
                            lastUpdatedAt = now
                        }
                }
            }
            
            viewModel.updated = {
                if !calibrationMode {
                    tapCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    arCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                } else {
                    let x = Double(viewModel.transform.columns.3.x)
                    let y = -Double(viewModel.transform.columns.3.z)
                    let sin_rotation = sin(rotation)
                    let cos_rotation = cos(rotation)
                    let xy = (
                        calibration.0 + cos_rotation * x - sin_rotation * y,
                        calibration.1 + sin_rotation * x + cos_rotation * y
                    )
                    if let coordinate = site?.fromXY(xy) {
                        arCoord = coordinate
                    }
                }
                updatePoints(style: mapStyle)
            }
        }
    }
}

#Preview {
    let radarDelegateState = RadarDelegateState()
    let radarDelegate = MyRadarDelegate()
    
    DebugView(radarDelegateState: radarDelegateState).onAppear {
        radarDelegate.state = radarDelegateState
        Radar.setDelegate(radarDelegate)
    }
}
