//
//  RadarTripIntegrationTests.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/31/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import CoreLocation
import Testing

import RadarSDK

private struct TripLegUpdateResult {
    let status: RadarStatus
    let tripId: String?
    let legId: String?
}

private struct TripLegValidationResult {
    let status: RadarStatus
    let tripIsNil: Bool
    let legIsNil: Bool
}

extension RadarSerializedTests {
    @Suite(.serialized)
    struct RadarTripIntegrationTests { // swiftlint:disable:this type_body_length
        
        init() {
            Radar.initialize(
                publishableKey:
                    "prj_test_pk_0000000000000000000000000000000000000000"
            )
            
            let apiHelperMock = RadarAPIHelperMock()
            apiHelperMock.mockStatus = .success
            RadarAPIClient.sharedInstance().apiHelper = apiHelperMock
            
            let locationManagerMock = TrackingCLLocationManager()
            let locationManager = RadarLocationManager.sharedInstance()
            locationManager.locationManager = locationManagerMock
            locationManager.lowPowerLocationManager = locationManagerMock
            locationManagerMock.delegate = locationManager
            
            let permissionsHelperMock = RadarPermissionsHelperMock()
            permissionsHelperMock.mockLocationAuthorizationStatus = .authorizedAlways
            locationManager.permissionsHelper = permissionsHelperMock
            
            RadarTripIntegrationTestSupport.resetState()
        }
        
        @Test("startTrip stores the trip options")
        func startTripStoresOptions() throws {
            let options = RadarTripOptions(
                externalId: "tripExternalId",
                destinationGeofenceTag:
                    "tripDestinationGeofenceTag",
                destinationGeofenceExternalId:
                    "tripDestinationExternalId"
            )
            options.metadata = [
                "foo": "bar",
                "baz": true,
                "qux": 1,
            ]
            options.mode = .foot
            
            Radar.startTrip(options: options)
            
            let storedOptions = try #require(
                Radar.getTripOptions()
            )
            #expect(storedOptions.isEqual(options))
        }
        
        @Test("completeTrip clears the trip options")
        func completeTripClearsOptions() {
            Radar.completeTrip()
            
            #expect(Radar.getTripOptions() == nil)
        }
        
        @Test("cancelTrip clears the trip options")
        func cancelTripClearsOptions() {
            Radar.cancelTrip()
            
            #expect(Radar.getTripOptions() == nil)
        }
        
        @Test("trip tracking preserves existing tracking options")
        func tripPreservesExistingTrackingOptions() async {
            let originalTrackingOptions =
                RadarTrackingOptions.presetEfficient
            Radar.startTracking(
                trackingOptions: originalTrackingOptions
            )
            
            let tripOptions = RadarTripOptions(
                externalId: "testTrip",
                destinationGeofenceTag: "someTag",
                destinationGeofenceExternalId: "someId"
            )
            let tripTrackingOptions =
                RadarTrackingOptions.presetContinuous
            
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Radar.startTrip(
                    options: tripOptions,
                    trackingOptions: tripTrackingOptions
                ) { _, _, _ in
                    continuation.resume()
                }
            }
            
            #expect(
                RadarTripIntegrationTestSupport
                    .previousTrackingOptionsEqual(
                        to: originalTrackingOptions
                    )
            )
            
            #expect(
                Radar.getTrackingOptions()
                    .isEqual(tripTrackingOptions)
            )
            
            await Radar.completeTrip()
            
            #expect(
                !RadarTripIntegrationTestSupport
                    .hasPreviousTrackingOptions()
            )
            #expect(
                Radar.getTrackingOptions()
                    .isEqual(originalTrackingOptions)
            )
            #expect(Radar.isTracking())
        }
        
        @Test("trip tracking stops when tracking was not already active")
        func tripStopsWhenTrackingWasNotActive() async {
            let tripOptions = RadarTripOptions(
                externalId: "testTrip",
                destinationGeofenceTag: "someTag",
                destinationGeofenceExternalId: "someId"
            )
            let tripTrackingOptions =
            RadarTrackingOptions.presetContinuous
            
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Radar.startTrip(
                    options: tripOptions,
                    trackingOptions: tripTrackingOptions
                ) { _, _, _ in
                    continuation.resume()
                }
            }
            
            #expect(
                !RadarTripIntegrationTestSupport
                    .hasPreviousTrackingOptions()
            )
            
            #expect(
                Radar.getTrackingOptions()
                    .isEqual(tripTrackingOptions)
            )
            
            await Radar.completeTrip()
            
            #expect(
                !RadarTripIntegrationTestSupport
                    .hasPreviousTrackingOptions()
            )
            #expect(!Radar.isTracking())
        }
        
        @Test("getTrip returns nil when no trip is stored")
        func getTripReturnsNilWithoutStoredTrip() {
            #expect(Radar.getTrip() == nil)
        }
        
        @Test("getTrip returns the stored multi-leg trip")
        func getTripReturnsStoredTrip() throws {
            RadarTripIntegrationTestSupport.storeMultiLegTrip()
            
            let trip = try #require(Radar.getTrip())
            let legs = try #require(trip.legs)
            
            #expect(trip._id == "trip_abc123")
            #expect(legs.count == 2)
            #expect(trip.currentLegId == "leg_001")
        }

        @Test("startTrip stores the returned trip")
        func startTripStoresReturnedTrip() async throws {
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            let options = RadarTripOptions(
                externalId: "order-456",
                destinationGeofenceTag: "store",
                destinationGeofenceExternalId: "store-1"
            )

            await Radar.startTrip(options: options)

            let trip = try #require(Radar.getTrip())
            #expect(trip._id == "trip_abc123")
        }

        @Test("completeTrip clears the stored trip and options")
        func completeTripClearsStoredTrip() async {
            RadarTripIntegrationTestSupport
                .storeMultiLegTripAndOptions()
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            await Radar.completeTrip()

            #expect(Radar.getTrip() == nil)
            #expect(Radar.getTripOptions() == nil)
        }

        @Test("cancelTrip clears the stored trip and options")
        func cancelTripClearsStoredTrip() async {
            RadarTripIntegrationTestSupport
                .storeMultiLegTripAndOptions()
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            await Radar.cancelTrip()

            #expect(Radar.getTrip() == nil)
            #expect(Radar.getTripOptions() == nil)
        }

        @Test("updateTripLeg returns and stores the updated trip")
        func updateTripLegSucceeds() async {
            RadarTripIntegrationTestSupport.storeMultiLegTrip()
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            let result: TripLegUpdateResult =
                await withCheckedContinuation { continuation in
                    Radar.updateTripLeg(
                        tripId: "trip_abc123",
                        legId: "leg_001",
                        status: .completed
                    ) { status, trip, leg, _ in
                        continuation.resume(
                            returning: TripLegUpdateResult(
                                status: status,
                                tripId: trip?._id,
                                legId: leg?._id
                            )
                        )
                    }
                }

            #expect(result.status == .success)
            #expect(result.tripId == "trip_abc123")
            #expect(result.legId == "leg_001")
            #expect(Radar.getTrip() != nil)
        }

        @Test("updateTripLeg sends the expected request")
        func updateTripLegSendsExpectedRequest() async {
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Radar.updateTripLeg(
                    tripId: "trip_abc123",
                    legId: "leg_001",
                    status: .completed
                ) { _, _, _, _ in
                    continuation.resume()
                }
            }

            #expect(
                RadarTripIntegrationTestSupport
                    .lastRequestWasCompletedLegUpdate()
            )
        }

        @Test("updateTripLeg fails when no trip is active")
        func updateTripLegFailsWithoutActiveTrip() async {
            let result: TripLegValidationResult =
                await withCheckedContinuation { continuation in
                    Radar.updateTripLeg(
                        legId: "leg_001",
                        status: .completed
                    ) { status, trip, leg, _ in
                        continuation.resume(
                            returning: TripLegValidationResult(
                                status: status,
                                tripIsNil: trip == nil,
                                legIsNil: leg == nil
                            )
                        )
                    }
                }

            #expect(result.status == .errorBadRequest)
            #expect(result.tripIsNil)
            #expect(result.legIsNil)
        }

        @Test("updateCurrentTripLeg fails without a current leg")
        func updateCurrentTripLegFailsWithoutCurrentLeg() async throws {
            RadarTripIntegrationTestSupport
                .storeTripWithoutCurrentLeg()

            let trip = try #require(Radar.getTrip())
            #expect(trip.currentLegId == nil)

            let status: RadarStatus =
                await withCheckedContinuation { continuation in
                    Radar.updateCurrentTripLeg(
                        status: .completed
                    ) { status, _, _, _ in
                        continuation.resume(returning: status)
                    }
                }

            #expect(status == .errorBadRequest)
        }

        @Test("reorderTripLegs returns the trip and sends the new order")
        func reorderTripLegsSucceeds() async {
            RadarTripIntegrationTestSupport
                .configureMultiLegTripResponse()

            let result: (
                status: RadarStatus,
                tripId: String?
            ) = await withCheckedContinuation { continuation in
                Radar.reorderTripLegs(
                    tripId: "trip_abc123",
                    legIds: ["leg_002", "leg_001"]
                ) { status, trip, _ in
                    continuation.resume(
                        returning: (
                            status,
                            trip?._id
                        )
                    )
                }
            }

            #expect(result.status == .success)
            #expect(result.tripId == "trip_abc123")
            #expect(
                RadarTripIntegrationTestSupport
                    .lastRequestWasLegReorder()
            )
        }

        @Test("reorderTripLegs fails when no trip is active")
        func reorderTripLegsFailsWithoutActiveTrip() async {
            let result: (
                status: RadarStatus,
                tripIsNil: Bool
            ) = await withCheckedContinuation { continuation in
                Radar.reorderTripLegs(
                    legIds: ["leg_001", "leg_002"]
                ) { status, trip, _ in
                    continuation.resume(
                        returning: (
                            status,
                            trip == nil
                        )
                    )
                }
            }

            #expect(result.status == .errorBadRequest)
            #expect(result.tripIsNil)
        }
    }
}
