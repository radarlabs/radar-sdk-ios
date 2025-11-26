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

extension CMAcceleration {
    func magnitude() -> Double {
        return (self.x * self.x + self.y * self.y + self.z * self.z).squareRoot()
    }
    
    func add(_ other: CMAcceleration) -> CMAcceleration {
        return CMAcceleration(x: self.x + other.x, y: self.y + other.y, z: self.z + other.z)
    }
}

func circleFor(site: RadarSite, x: Double, y: Double, r: Double) -> [CLLocationCoordinate2D] {
    var coordinates: [CLLocationCoordinate2D] = []
    for i in 0...32 {
        let angle = 2.0 * Double.pi * Double(i) / 32.0
        let dx = r * cos(angle)
        let dy = r * sin(angle)

        coordinates.append(site.fromXY((x + dx, y + dy)))
    }
    // close ring
    return coordinates
}




struct DebugView: View {
    
    @State
    var tapCoordinates: CLLocationCoordinate2D? = nil
    
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
    
    @State
    var prevMeasurement = [String: Int]()
    
    @State
    var fillCount = [String: Int]()
    
    @AppStorage("radar-prediction-average-window") var predictionAverageWindow: Int = 1
    @AppStorage("radar-measurement-drop-filter") var measurementDropFilter: Int = 0
    @AppStorage("radar-calibration-mode") var calibrationMode: Bool = false
    @AppStorage("radar-kalman-filter") var kalmanFilter: Bool = true
    @AppStorage("radar-raw-prediction") var rawPrediction: Bool = false
    @AppStorage("radar-prediction-confidence") var predictionConfidence: Bool = false

    @State
    var predictionHistory = [(Double, Double)]()
    
    @State
    var acceleration = [Double]()
    @State
    var acceleration_xyz = [CMAcceleration]()
    
    let motionManager = CMMotionManager()
    
    let kalman = KalmanFilter()
    
    func onRangedBeacon(beacons: [CLBeacon]) {
        ranged = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ranged = false
        }
        
        acceleration.removeAll(keepingCapacity: true)
        acceleration_xyz.removeAll(keepingCapacity: true)
        
        // send data to server if surveying
        Task {
            if (surveying) {
                let x = Double(viewModel.transform.columns.3.x)
                let y = -Double(viewModel.transform.columns.3.z)
                let sin_rotation = sin(rotation)
                let cos_rotation = cos(rotation)
                let xy = (
                    calibration.0 + cos_rotation * x - sin_rotation * y,
                    calibration.1 + sin_rotation * x + cos_rotation * y
                )
                success = await RadarSDKIndoors.setLocation(xy, beacons)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    success = false
                }
            }
        }
        // update prediction
        Task {
            let rssi = beacons.reduce(into: [String: Int]()) { result, beacon in
                let name = "_\(beacon.major)_\(beacon.minor)"
                var beaconRssi = beacon.rssi
                if beaconRssi == 0 && prevMeasurement[name, default: 0] != 0 && fillCount[name, default: 0] < measurementDropFilter {
                    beaconRssi = prevMeasurement[name, default: 0]
                    fillCount[name, default: 0] += 1
                } else {
                    fillCount[name, default: 0] = 0
                }
                result[name] = beaconRssi
            }
            prevMeasurement = rssi
            if let pred = (await RadarSDKIndoors.getLocation(rssi: rssi)) {
                
                var xy = (pred.0, pred.1)
                if (kalmanFilter) {
                    let kalmanPred = kalman.predict()
                    xy = (kalmanPred.x, kalmanPred.y)
                    kalman.update(z: simd_double2(pred.0, pred.1))
                    
                    if let source = mapStyle?.source(withIdentifier: "pred-conf-src"),
                       let shape = source as? MLNShapeSource {
                        let error = kalman.error_radius()
                        if (predictionConfidence) {
                            shape.shape = MLNPolygon(coordinates: circleFor(site: site!, x: xy.0, y: xy.1, r: error), count: 32)
                        } else {
                            // send shape to 0,0 so we don't see it anymore
                            shape.shape = MLNPointFeature(coordinate: CLLocationCoordinate2D())
                        }
                    }
                    
                    if let source = mapStyle?.source(withIdentifier: "raw-pred-src"),
                       let pointSource = source as? MLNShapeSource,
                       let coordinate = site?.fromXY(pred) {
                        pointSource.shape = MLNPointFeature(coordinate: rawPrediction ? coordinate : CLLocationCoordinate2D())
                    }
                } else {
                    predictionHistory.append(pred)
                    if (predictionHistory.count > predictionAverageWindow) {
                        predictionHistory.removeFirst()
                    }
                    let predSum = predictionHistory.reduce((0, 0)) { (result, pred) in
                        return (result.0 + pred.0, result.1 + pred.1)
                    }
                    xy = (predSum.0 / Double(predictionHistory.count), predSum.1 / Double(predictionHistory.count))
                }
                
                if let source = mapStyle?.source(withIdentifier: "pred-src"),
                   let pointSource = source as? MLNShapeSource,
                   let coordinate = site?.fromXY(xy) {
                    pointSource.shape = MLNPointFeature(coordinate: coordinate)
                }
            }
        }
        
    }
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        VStack(spacing: 10) {
            MyMapView(withRadar: "prj_test_pk_3508428416f485c5f54d8e8bb1f616ee405b1995")
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
                        url: URL(string: "https://api-shicheng.radar-staging.com/api/v1/assets/\(site.floorplan.path)")!
                    )
                    style.addSource(imageSource)
                    let rasterLayer = MLNRasterStyleLayer(identifier: "overlay‑layer", source: imageSource)
                    style.addLayer(rasterLayer)
                    
                    let pointsSource = MLNShapeSource(identifier: "points-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(pointsSource)
                    let pointsLayer = MLNCircleStyleLayer(identifier: "points-layer", source: pointsSource)
                    pointsLayer.circleRadius = NSExpression(forConstantValue: 5)
                    pointsLayer.circleColor = NSExpression(forConstantValue: UIColor.yellow)
                    style.addLayer(pointsLayer)
                    
                    let arSource = MLNShapeSource(identifier: "ar-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(arSource)
                    let arLayer = MLNCircleStyleLayer(identifier: "ar-layer", source: arSource)
                    arLayer.circleRadius = NSExpression(forConstantValue: 5)
                    arLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
                    style.addLayer(arLayer)
                    
                    let predConfSource = MLNShapeSource(identifier: "pred-conf-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(predConfSource)
                    let predConfLayer = MLNFillStyleLayer(identifier: "pred-conf-layer", source: predConfSource)
                    predConfLayer.fillColor = NSExpression(forConstantValue: UIColor.green)
                    style.addLayer(predConfLayer)
                    
                    let predSource = MLNShapeSource(identifier: "pred-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(predSource)
                    let predLayer = MLNCircleStyleLayer(identifier: "pred-layer", source: predSource)
                    predLayer.circleRadius = NSExpression(forConstantValue: 5)
                    predLayer.circleColor = NSExpression(forConstantValue: UIColor.blue)
                    style.addLayer(predLayer)
                    
                    let rawPredSource = MLNShapeSource(identifier: "raw-pred-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(rawPredSource)
                    let rawPredLayer = MLNCircleStyleLayer(identifier: "raw-pred-layer", source: rawPredSource)
                    rawPredLayer.circleRadius = NSExpression(forConstantValue: 5)
                    rawPredLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
                    style.addLayer(rawPredLayer)
                    
                }
                .onTapMapGesture { value in
                    tapCoordinates = value.coordinate
                    if let source = value.mapView.style?.source(withIdentifier: "points-src"),
                       let pointSource = source as? MLNShapeSource {
                        pointSource.shape = MLNPointFeature(coordinate: value.coordinate)
                    }
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
                        if let coords = tapCoordinates,
                           let xy = site?.toXY(coords) {
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
                        
                        Button(action: {
                            viewModel.resetTracking()
                            if let coords = tapCoordinates,
                               let calib = site?.toXY(coords) {
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
                        }) {
                            Text(surveying ? "Stop" : "Start")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(surveying ? Color.red : Color.green)
                                .clipShape(Circle())
                        }
                        Button(action: {
                            Task {
                                await RadarSDKIndoors.reDownloadModel()
                            }
                        }) {
                            Text("Re-download model")
                                .foregroundColor(.white)
                        }
                    }.frame(width: 200)
                }
            }
        }.onAppear {
            
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                guard let motion else { return }
                acceleration.append(motion.userAcceleration.magnitude())
                acceleration_xyz.append(motion.userAcceleration)
            }
            
            RadarSDKIndoors.nothing()
            Task {
                await RadarSDKIndoors.start()
                
                // get a location first, so that we load the model
                //                    if (await RadarSDKIndoors.getLocation()) != nil {
                //                    }
                RadarSDKIndoors.onRangedBeacon(onRangedBeacon)
            }
            viewModel.updated = {
                if !calibrationMode {
                    if let source = mapStyle?.source(withIdentifier: "ar-src"),
                       let pointSource = source as? MLNShapeSource {
                        pointSource.shape = MLNPointFeature(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                    }
                    if let source = mapStyle?.source(withIdentifier: "points-src"),
                       let pointSource = source as? MLNShapeSource {
                        pointSource.shape = MLNPointFeature(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
                    }
                    return;
                }
                if let source = mapStyle?.source(withIdentifier: "ar-src"),
                   let pointSource = source as? MLNShapeSource {
                    let x = Double(viewModel.transform.columns.3.x)
                    let y = -Double(viewModel.transform.columns.3.z)
                    let sin_rotation = sin(rotation)
                    let cos_rotation = cos(rotation)
                    let xy = (
                        calibration.0 + cos_rotation * x - sin_rotation * y,
                        calibration.1 + sin_rotation * x + cos_rotation * y
                    )
                    if let coordinate = site?.fromXY(xy) {
                        pointSource.shape = MLNPointFeature(coordinate: coordinate)
                    }
                }
            }
        }
    }
}

#Preview {
    DebugView()
}
