//
//  MapView.swift
//  Example
//
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapLibre



import MapLibreSwiftUI
import MapLibreSwiftDSL
extension MapView where T == MLNMapViewController {
    init(withRadar publishableKey: String) {
        let style = "radar-default-v1"
        let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")!
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["X-Radar-Mobile-Origin": Bundle.main.bundleIdentifier ?? ""]
        sessionConfig.httpAdditionalHeaders?["Authorization"] = publishableKey
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
        
        self.init(styleURL: styleURL)
    }
}


struct GestureContext {
    var point: CGPoint
    var coordinate: CLLocationCoordinate2D
    var mapView: MLNMapView
}

// delegate for map interactions
// https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnmapviewdelegate
class MapViewDelegate: NSObject, MLNMapViewDelegate {
    var parent: MyMapView
    var isMapLoaded = false
    
    init(_ parent: MyMapView) {
        self.parent = parent
    }
    
    // handle map and style loaded
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        self.isMapLoaded = true
        parent.onStyleLoaded?(style)
    }

    func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
        self.isMapLoaded = true
    }
    
    // handle annotation
    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        let markerId = "marker";
        
        if let annotationImage = mapView.dequeueReusableAnnotationView(withIdentifier: markerId) {
            return annotationImage
        } else {
            guard let image = UIImage(named: markerId) else {
                return nil
            }
            let annotationView = MLNAnnotationView(reuseIdentifier: markerId)
            annotationView.addSubview(UIImageView(image: image))
            annotationView.frame.size = image.size
            // shift pin up so that the bottom is where the user clicked
            annotationView.centerOffset.dy = -image.size.height / 2
            
            return annotationView
        }
    }
    
    // handle marker view selected
    func mapView(_ mapView: MLNMapView, didSelect markerView: MLNAnnotationView) {
        let imageView = markerView.subviews.first as! UIImageView
        imageView.image = UIImage(named:"marker-selected")
        // markerView.annotation to access to underlying MLNAnnotation
    }
    
    // update marker image on deselect
    func mapView(_ mapView: MLNMapView, didDeselect markerView: MLNAnnotationView) {
        let imageView = markerView.subviews.first as! UIImageView
        imageView.image = UIImage(named:"marker")
        // markerView.annotation to access to underlying MLNAnnotation
    }
    
    // show popup
    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
        return true
    }

    // handle map tap - create new marker at tap location
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
        guard let mapView = sender.view as? MLNMapView else { return }

        // convert tap location to geographic coordinate
        let tapPoint: CGPoint = sender.location(in: mapView)
        let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        print("Map tapped at coordinate: \(tapCoordinate.latitude), \(tapCoordinate.longitude)")
        
        if isMapLoaded {
            parent.onTap?(GestureContext(point: tapPoint, coordinate: tapCoordinate, mapView: mapView))
        } else {
            print("Map is not loaded yet")
        }
    }
}

struct MyMapView: UIViewRepresentable {
    
    var withRadar: String
    var onStyleLoaded: ((MLNStyle) -> Void)? = nil
    var onTap: ((GestureContext) -> Void)? = nil

    func makeCoordinator() -> MapViewDelegate {
        MapViewDelegate(self)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let style = "radar-default-v1"
        let publishableKey = withRadar
        let styleURL = URL(string: "https://api.radar-staging.com/maps/styles/\(style)?publishableKey=\(publishableKey)")
        
        // set up radar request header, required for the mobile restrictions setting.
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = ["X-Radar-Mobile-Origin": Bundle.main.bundleIdentifier ?? ""]
        sessionConfig.httpAdditionalHeaders?["Authorization"] = publishableKey
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
        
        // create new map view
        // https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnmapview
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        mapView.isRotateEnabled = false

        mapView.setCenter(CLLocationCoordinate2D(latitude: 40.73840359056395, longitude: -73.99118515629965), zoomLevel: 18, animated: false)

        // set min and max zoom levels
        mapView.maximumZoomLevel = 25
        mapView.minimumZoomLevel = 1
        mapView.allowsTilting = false
        
        // setup map tap listener
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        // add Radar logo
        let logoImageView = UIImageView(image: UIImage(named: "radar-logo"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(logoImageView)
        NSLayoutConstraint.activate([
          logoImageView.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
          logoImageView.leadingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.leadingAnchor, constant: 10),
          logoImageView.widthAnchor.constraint(equalToConstant: 74),
          logoImageView.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        // setup map delegate
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
        // Update the map view if needed
    }
    
    func onTapMapGesture(_ onTap: @escaping (GestureContext) -> Void) -> MyMapView {
        var copy = self
        copy.onTap = onTap
        return copy
    }
    
    func onStyleLoaded(_ onStyleLoaded: @escaping (MLNStyle) -> Void) -> MyMapView {
        var copy = self
        copy.onStyleLoaded = onStyleLoaded
        return copy
    }
}

#Preview {
    MyMapView(withRadar: "prj_test_pk_c0ebf059d9895f428fac2295dbe83568507938e3")
}
