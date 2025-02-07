//
//  MapView.swift
//  Example
//
//  Created by Greg Sadetsky on 2/7/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

import SwiftUI
import MapLibre

class MapViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    weak var mapCoordinator: MapView.Coordinator?  // Add this to store coordinator reference
    var confidenceLabel: UILabel?  // Add this
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapHostingController = UIHostingController(rootView: MapView(
            fetchGeofences: appDelegate.fetchAllGeofences,
            onGeofenceTap: { id, description, completion in
                // Your existing tap handler function with completion
                self.appDelegate.didTapGeofenceButton(id, description) {
                    completion()
                }
            },
            onCoordinatorCreated: { [weak self] coordinator in  // Add this callback
                self?.mapCoordinator = coordinator
            }
        ))
        
        // Add a label for confidence
        let confidenceLabel = UILabel()
        confidenceLabel.textAlignment = .center
        confidenceLabel.translatesAutoresizingMaskIntoConstraints = false
        self.confidenceLabel = confidenceLabel

        addChild(mapHostingController)
        view.addSubview(mapHostingController.view)
        view.addSubview(confidenceLabel)

        mapHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mapHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapHostingController.view.heightAnchor.constraint(equalToConstant: 700),

            confidenceLabel.topAnchor.constraint(equalTo: mapHostingController.view.bottomAnchor, constant: 50), // changed from 10 to 30
            confidenceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confidenceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confidenceLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
        mapHostingController.didMove(toParent: self)
}

    func handlePrediction(geofenceId: String, confidence: Double) {
        print("Handling prediction", geofenceId, confidence)
        if let coordinator = mapCoordinator {
            print("calling coordinator.updateHighlight")
            coordinator.updateHighlight(geofenceId: geofenceId)

            print("confidenceLabel", confidenceLabel)
            confidenceLabel?.text = String(format: "Confidence: %.1f%%", confidence * 100)
        } else {
            print("Coordinator not found!!!!!!!!!!!!")
        }
    }
}

struct MapView: UIViewRepresentable {
    let fetchGeofences: (@escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) -> Void
    let onGeofenceTap: (String, String, @escaping () -> Void) -> Void  // Updated with completion
    let onCoordinatorCreated: (Coordinator) -> Void  // Add this

    init(
        fetchGeofences: @escaping (@escaping ([(String, String, [[CLLocationCoordinate2D]], String)]) -> Void) -> Void,
        onGeofenceTap: @escaping (String, String, @escaping () -> Void) -> Void,
        onCoordinatorCreated: @escaping (Coordinator) -> Void
    ) {
        self.fetchGeofences = fetchGeofences
        self.onGeofenceTap = onGeofenceTap
        self.onCoordinatorCreated = onCoordinatorCreated
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(self)
        onCoordinatorCreated(coordinator)  // Store reference when coordinator is created
        return coordinator
    }

    func makeUIView(context: Context) -> MLNMapView {
        // create a map

        let style = "radar-default-v1"
        let publishableKey = "prj_test_pk_2e4715e49b97eb6b09e4f1035068548ccfeeb683"
        let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")

        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        mapView.showsUserLocation = true

        mapView.setCenter(
          CLLocationCoordinate2D(latitude: 40.7342, longitude: -73.9911),
          zoomLevel: 11,
          animated: false
        )
        
        mapView.delegate = context.coordinator

        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {

    }
    
    // add a marker on map load

    class Coordinator: NSObject, MLNMapViewDelegate {
        var mapView: MLNMapView?
        var geofenceIdToLayer: [String: (MLNFillStyleLayer, MLNLineStyleLayer)] = [:]
        var control: MapView
        var isProcessing = false
        var statusLabel: UILabel?  // Move the label here

        init(_ control: MapView) {
            self.control = control
        }

        func setupStatusLabel(in mapView: MLNMapView) {
            let label = UILabel()
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = .white
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.isHidden = true
            label.text = "Surveying..."
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            mapView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -20),
                label.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                label.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            self.statusLabel = label
        }
        
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            self.mapView = mapView
            setupStatusLabel(in: mapView)  // Setup the label when map loads
            
            // Add tap recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
            mapView.addGestureRecognizer(tapGesture)

            // Fetch and add geofences once the map style is loaded
            control.fetchGeofences { geofences in
               DispatchQueue.main.async {
                   self.addGeofences(to: style, geofences: geofences)
               }
           }
       }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard !isProcessing, let mapView = self.mapView else { return }
            
            let point = gesture.location(in: mapView)
            let features = mapView.visibleFeatures(
                at: point,
                styleLayerIdentifiers: Set(geofenceIdToLayer.keys.map { "geofence-fill-\($0)" })
            )
            
            if let polygonFeature = features.first as? MLNPolygonFeature,
               let geofenceId = polygonFeature.identifier as? String {
                print("Tapped geofence with id:", geofenceId)
                
                isProcessing = true
                mapView.isUserInteractionEnabled = false
                statusLabel?.isHidden = false  // Show the label

                control.onGeofenceTap(geofenceId, "description") {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        mapView.isUserInteractionEnabled = true
                        self.statusLabel?.isHidden = true  // Hide the label
                    }
                }
            }
        }

        func updateHighlight(geofenceId: String?) {
            print("updateHighlight", geofenceId)

            // Reset all geofences to original style
            for (id, (fillLayer, strokeLayer)) in geofenceIdToLayer {
                let (fillColor, strokeColor, fillOpacity, strokeWidth) = styleForTag(id)
                fillLayer.fillColor = NSExpression(forConstantValue: fillColor.withAlphaComponent(fillOpacity))
                strokeLayer.lineColor = NSExpression(forConstantValue: strokeColor)
                strokeLayer.lineWidth = NSExpression(forConstantValue: strokeWidth)
            }
            
            // Highlight selected geofence
            if let id = geofenceId, let (fillLayer, strokeLayer) = geofenceIdToLayer[id] {
                fillLayer.fillColor = NSExpression(forConstantValue: UIColor.red.withAlphaComponent(0.5))
                strokeLayer.lineColor = NSExpression(forConstantValue: UIColor.red)
                strokeLayer.lineWidth = NSExpression(forConstantValue: 3.0)
            }
        }

        func addGeofences(to style: MLNStyle, geofences: [(String, String, [[CLLocationCoordinate2D]], String)]) {
            for (id, _, coordinates, tag) in geofences {
                let outerRing = coordinates[0]
                
                // let polygon = MLNPolygon(coordinates: outerRing, count: UInt(outerRing.count))
                let feature = MLNPolygonFeature(coordinates: outerRing, count: UInt(outerRing.count))
                feature.identifier = id  // Set the id directly on the feature
                
                let shapeSource = MLNShapeSource(identifier: "geofence-source-\(id)", shape: feature, options: nil)
                
                let fillLayer = MLNFillStyleLayer(identifier: "geofence-fill-\(id)", source: shapeSource)
                let strokeLayer = MLNLineStyleLayer(identifier: "geofence-stroke-\(id)", source: shapeSource)
                
                let (fillColor, strokeColor, fillOpacity, strokeWidth) = styleForTag(tag)
                
                fillLayer.fillColor = NSExpression(forConstantValue: fillColor.withAlphaComponent(fillOpacity))
                strokeLayer.lineColor = NSExpression(forConstantValue: strokeColor)
                strokeLayer.lineWidth = NSExpression(forConstantValue: strokeWidth)
                
                style.addSource(shapeSource)
                style.addLayer(fillLayer)
                style.addLayer(strokeLayer)
                
                geofenceIdToLayer[id] = (fillLayer, strokeLayer)
            }
        }
        
        private func styleForTag(_ tag: String) -> (UIColor, UIColor, CGFloat, CGFloat) {
            switch tag {
            case "airport":
                return (UIColor.gray, UIColor.darkGray, 0.1, 2.0)
            case "lga":
                return (UIColor.blue, UIColor.blue, 0.2, 1.5)
            case "lga-gates":
                return (UIColor.green, UIColor.green, 0.3, 1.0)
            default: // geofenceoffice tags
                return (UIColor.purple, UIColor.purple, 0.2, 1.0)
            }
        }

    }
}
