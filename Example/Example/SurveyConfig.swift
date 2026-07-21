// swift-format-ignore-file
//
//  SurveyConfig.swift
//  Example
//
//  Created by ShiCheng Lu on 10/30/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

/// The single place to configure an indoor survey. Edit these values to point the Survey
/// tab at a different site, beacons, or geofence.
///
/// Note: there is no survey-record id to set here — the server generates it when
/// `SurveyApi.createSurvey` runs. What you configure is the geofence the survey attaches to.
enum SurveyConfig {

    /// iBeacon proximity UUID(s) the survey ranges. One UUID matches every beacon with it;
    /// individual beacons are distinguished downstream by major/minor. 
    static let beaconUUIDs = [
        "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
    ]

    /// Geofence the survey attaches to. Must match a geofence in `siteJSON` below.
    static let geofenceId = "6a58e91773de2ed51b43673f"

    /// Sent to the API with the survey record.
    static let surveyor = "chicago-home"
    static let surveyDescription = "Chicago Home"

    /// The site being surveyed (floorplan image, geometry, calibration, geofence).
    static let siteJSON = """
{
    "meta": {
        "code": 200
    },
    "site": {
        "_id": "6a58e7809ab9ba8601cb0c45",
        "createdAt": "2026-07-16T14:15:28.248Z",
        "updatedAt": "2026-07-21T02:08:49.852Z",
        "project": "69de47daca4389afc3fa8e23",
        "live": true,
        "description": "home",
        "geometry": {
            "type": "Point",
            "coordinates": [
                -87.61611323288939,
                41.886331259878865
            ]
        },
        "geofences": [
            {
                "_id": "6a58e91773de2ed51b43673f",
                "createdAt": "2026-07-16T14:22:15.751Z",
                "updatedAt": "2026-07-21T02:08:49.824Z",
                "live": true,
                "description": "home-tight",
                "metadata": {},
                "tag": "home-tight",
                "externalId": "home-tight",
                "type": "polygon",
                "mode": "car",
                "geometryCenter": {
                    "type": "Point",
                    "coordinates": [
                        -87.61612999660954,
                        41.88632911609379
                    ]
                },
                "geometryRadius": 30,
                "disallowedPrecedingTagSubstrings": [],
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [
                                -87.61617695129796,
                                41.88639124448186
                            ],
                            [
                                -87.61617300552548,
                                41.88626551894984
                            ],
                            [
                                -87.61608304192137,
                                41.88626669395536
                            ],
                            [
                                -87.6160869876934,
                                41.886393006988115
                            ],
                            [
                                -87.61617695129796,
                                41.88639124448186
                            ]
                        ]
                    ]
                },
                "userIds": [],
                "ip": [],
                "enabled": true
            }
        ],
        "beacons": [
            {
                "_id": "6a5ed379c6f9382494da1e6c",
                "createdAt": "2026-07-21T02:03:37.435Z",
                "updatedAt": "2026-07-21T02:15:36.906Z",
                "live": true,
                "description": "beacon1test",
                "tag": "beacon1test",
                "externalId": "bacon1text",
                "metadata": {},
                "enabled": true,
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        -87.61609236274282,
                        41.88630080834719
                    ]
                },
                "type": "ibeacon",
                "uuid": "F7826DA6-4FA2-4E98-8024-BC5B71E0893E",
                "major": "46782",
                "minor": "35995"
            },
            {
                "_id": "6a5ed391b5e5e82fc362c21b",
                "createdAt": "2026-07-21T02:04:01.826Z",
                "updatedAt": "2026-07-21T02:14:57.095Z",
                "live": true,
                "description": "bacon2test",
                "tag": "bacon2test",
                "externalId": "bacon2test",
                "metadata": {},
                "enabled": true,
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        -87.6161647823863,
                        41.88634324091453
                    ]
                },
                "type": "ibeacon",
                "uuid": "F7826DA6-4FA2-4E98-8024-BC5B71E0893E",
                "major": "55469",
                "minor": "7449"
            },
            {
                "_id": "6a5ed3b77b8d89e4eff4edeb",
                "createdAt": "2026-07-21T02:04:39.372Z",
                "updatedAt": "2026-07-21T02:16:04.420Z",
                "live": true,
                "description": "bacon3test",
                "tag": "bacon3test",
                "externalId": "bacon3test",
                "metadata": {},
                "enabled": true,
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        -87.6160990682658,
                        41.886391164721346
                    ]
                },
                "type": "ibeacon",
                "uuid": "F7826DA6-4FA2-4E98-8024-BC5B71E0893E",
                "major": "19435",
                "minor": "65252"
            }
        ],
        "floorplan": {
            "path": "69de47daca4389afc3fa8e23/60e4085c-06ef-41de-9474-9be946efd944.jpeg",
            "mimeType": "image/jpeg",
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [
                            -87.61620572430354,
                            41.88623477519258
                        ],
                        [
                            -87.61621253392329,
                            41.88642391751369
                        ],
                        [
                            -87.61602074119911,
                            41.886427744565154
                        ],
                        [
                            -87.61601393185549,
                            41.88623860203253
                        ],
                        [
                            -87.61620572430354,
                            41.88623477519258
                        ]
                    ]
                ]
            },
            "calibration": {
                "imageSize": {
                    "width": 816,
                    "height": 616
                },
                "calibrationPoints": [
                    {
                        "x": 468.1639921240337,
                        "y": 220.125786163522,
                        "_id": "6a5eceb4c6f9382494d8afd9"
                    },
                    {
                        "x": 662.0843275538031,
                        "y": 219.0775681341719,
                        "_id": "6a5eceb4c6f9382494d8afda"
                    }
                ],
                "measureLength": 5,
                "measureUnit": "m"
            }
        }
    }
}
"""
}
