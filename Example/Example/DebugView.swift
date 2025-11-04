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
    func toXY(coords: CLLocationCoordinate2D) -> (Double, Double) {
        let rel_lat = coords.latitude - geometry.coordinates[1]
        let rel_lng = coords.longitude - geometry.coordinates[0]
        
        return (rel_lng * cos(geometry.coordinates[1] * .pi / 180.0) * 111320, rel_lat * 111132)
    }
    
    func fromXY(xy: (Double, Double)) -> CLLocationCoordinate2D {
        let (x, y) = xy
        let rel_lat = y / 111132.0
        let rel_lng = x / (cos(geometry.coordinates[1] * .pi / 180.0) * 111320.0)
        
        return CLLocationCoordinate2D(latitude: rel_lat + geometry.coordinates[1], longitude: rel_lng + geometry.coordinates[0])
    }
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
    var surveying = false
    
    @StateObject private var viewModel = DebugViewModel()
    
    func onRangedBeacon() {
        ranged = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ranged = false
        }
        
        // send data to server if surveying
        Task {
            if (surveying) {
                let xy = (calibration.0 + Double(viewModel.transform.columns.3.x), calibration.1 - Double(viewModel.transform.columns.3.z))
                success = await RadarSDKIndoors.setLocation(xy)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    success = false
                }
            }
        }
        // update prediction
        Task {
            if let pred = (await RadarSDKIndoors.getLocation()) {
                if let source = mapStyle?.source(withIdentifier: "pred-src"),
                   let pointSource = source as? MLNShapeSource,
                   let coordinate = site?.fromXY(xy: pred) {
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
                    
                    let predSource = MLNShapeSource(identifier: "pred-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(predSource)
                    let predLayer = MLNCircleStyleLayer(identifier: "pred-layer", source: predSource)
                    predLayer.circleRadius = NSExpression(forConstantValue: 5)
                    predLayer.circleColor = NSExpression(forConstantValue: UIColor.blue)
                    style.addLayer(predLayer)
                    
                    let arSource = MLNShapeSource(identifier: "ar-src", shape: MLNPointFeature(coordinate: CLLocationCoordinate2D()))
                    style.addSource(arSource)
                    let arLayer = MLNCircleStyleLayer(identifier: "ar-layer", source: arSource)
                    arLayer.circleRadius = NSExpression(forConstantValue: 5)
                    arLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
                    style.addLayer(arLayer)
                }
                .onTapMapGesture { value in
                    tapCoordinates = value.coordinate
                    if let source = value.mapView.style?.source(withIdentifier: "points-src"),
                       let pointSource = source as? MLNShapeSource {
                        pointSource.shape = MLNPointFeature(coordinate: value.coordinate)
                    }
                }
            
            HStack(spacing: 20) {
                ARViewContainer(viewModel: viewModel).frame(width: 200)
                VStack {
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
                           let calib = site?.toXY(coords: coords) {
                            calibration = calib
                        }
                    }) {
                        Text("Calibrate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100) // Set a large size
                            .background(Color.yellow)
                            .clipShape(Circle()) // Make it round
                    }
                    
                    Button(action: {
                        surveying = !surveying
                    }) {
                        Text(surveying ? "Stop" : "Start")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100) // Set a large size
                            .background(surveying ? Color.red : Color.green)
                            .clipShape(Circle()) // Make it round
                    }
                }
            }.onAppear {
                RadarSDKIndoors.nothing()
                Task {
                    await RadarSDKIndoors.start()
                    
                    // get a location first, so that we load the model
                    if let pred = (await RadarSDKIndoors.getLocation()) {
                    }
                    RadarSDKIndoors.onRangedBeacon {
                        onRangedBeacon()
                    }
                }
                viewModel.updated = {
                    if let source = mapStyle?.source(withIdentifier: "ar-src"),
                       let pointSource = source as? MLNShapeSource,
                       let coordinate = site?.fromXY(xy: (calibration.0 + Double(viewModel.transform.columns.3.x), calibration.1 - Double(viewModel.transform.columns.3.z))) {
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
