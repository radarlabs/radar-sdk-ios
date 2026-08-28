//
//  RadarTripTestFixtures.swift
//  RadarSDK
//
//  Created by Alan Charles on 8/28/26.
//  Copyright © 2026 Radar Labs, Inc. All rights reserved.
//

import Foundation

enum RadarTripTestFixtures {

    static func trip() -> [String: Any] {
        [
            "_id": "trip_abc123",
            "externalId": "order-456",
            "metadata": [
                "driver": "testDriver"
            ],
            "destinationGeofenceTag": "store",
            "destinationGeofenceExternalId": "store-1",
            "destinationLocation": [
                "type": "Point",
                "coordinates": [-73.975365, 40.783825],
            ],
            "mode": "car",
            "eta": [
                "distance": 5_000.0,
                "duration": 12.5,
            ],
            "status": "started",
        ]
    }

    static func leg(
        id: String,
        status: String,
        tag: String,
        externalId: String
    ) -> [String: Any] {
        [
            "_id": id,
            "status": status,
            "createdAt": "2026-02-24T12:00:00.000Z",
            "updatedAt": "2026-02-24T12:05:00.000Z",
            "eta": [
                "duration": 5.0,
                "distance": 2_000.0,
            ],
            "destination": [
                "type": "geofence",
                "source": [
                    "geofence": "geofence_\(id)",
                    "data": [
                        "tag": tag,
                        "externalId": externalId,
                    ],
                ],
                "location": [
                    "coordinates": [-73.975365, 40.783825]
                ],
            ],
            "stopDuration": 10,
            "metadata": [
                "package": "small"
            ],
        ]
    }

    static func order(
        id: String,
        status: String = "fired"
    ) -> [String: Any] {
        [
            "id": id,
            "guid": "guid-\(id)",
            "handoffMode": "manual",
            "status": status,
            "firedAt": "2026-02-24T12:04:00.000Z",
            "firedAttempts": 2,
            "firedReason": "driver-arrived",
            "updatedAt": "2026-02-24T12:05:00.000Z",
        ]
    }
}
