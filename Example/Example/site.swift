//
//  site.swift
//  Example
//
//  Created by ShiCheng Lu on 10/30/25.
//  Copyright © 2025 Radar Labs, Inc. All rights reserved.
//

let siteString = """
{
    "meta": {
        "code": 200
    },
    "site": {
        "_id": "69a9df58accfc20568739f5d",
        "createdAt": "2026-03-05T19:54:00.866Z",
        "updatedAt": "2026-03-05T19:54:00.866Z",
        "project": "686d58e39c7af99e6bf5625a",
        "live": false,
        "description": "radar",
        "geometry": {
            "type": "Point",
            "coordinates": [
                -73.99110139105636,
                40.738360388235904
            ]
        },
        "geofences": [
            {
                "_id": "69a9df58accfc20568739f59",
                "createdAt": "2026-03-05T19:54:00.849Z",
                "updatedAt": "2026-03-05T19:54:00.848Z",
                "live": false,
                "description": "radar",
                "tag": "radar",
                "externalId": "radar",
                "type": "polygon",
                "geometryCenter": {
                    "type": "Point",
                    "coordinates": [
                        -73.99115930982342,
                        40.73847003253795
                    ]
                },
                "geometryRadius": 35,
                "disallowedPrecedingTagSubstrings": [],
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [
                                -73.99157421573746,
                                40.73852006229186
                            ],
                            [
                                -73.99088055907035,
                                40.738237842946894
                            ],
                            [
                                -73.99074197511881,
                                40.73842725035377
                            ],
                            [
                                -73.99144048936702,
                                40.738694974559245
                            ],
                            [
                                -73.99157421573746,
                                40.73852006229186
                            ]
                        ]
                    ]
                },
                "userIds": [],
                "ip": [],
                "enabled": true
            }
        ],
        "beacons": [],
        "floorplan": {
            "path": "686d58e39c7af99e6bf5625a/6c9365ba-e8b7-4819-a1dc-4568020b589b.png",
            "mimeType": "image/png",
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [
                            -73.99190174677312,
                            40.739379919726396
                        ],
                        [
                            -73.99030102416697,
                            40.739379919726396
                        ],
                        [
                            -73.99030103533954,
                            40.73734085674542
                        ],
                        [
                            -73.99190175794575,
                            40.73734085674542
                        ],
                        [
                            -73.99190174677312,
                            40.739379919726396
                        ]
                    ]
                ]
            },
            "calibration": {
                "imageSize": {
                    "width": 872,
                    "height": 1466
                },
                "calibrationPoints": [
                    {
                        "x": 275.06071511680364,
                        "y": 793.522702819023,
                        "_id": "69a9df58accfc20568739f5e"
                    },
                    {
                        "x": 579.9168947308916,
                        "y": 901.1190015063481,
                        "_id": "69a9df58accfc20568739f5f"
                    }
                ],
                "measureLength": 50,
                "measureUnit": "m"
            }
        }
    }
}
"""
