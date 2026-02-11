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
        "code": 200,
        "buildInfo": {
            "branchName": "jaysim/sre-2179-main-worker-migration",
            "sha": "f4396ec6fa9765f983392c53721afc735d2e879b",
            "date": "2026-02-11T20:54:12.848Z"
        }
    },
    "site": {
        "_id": "698cfb5b8b6de165a76b0ca2",
        "createdAt": "2026-02-11T21:57:47.534Z",
        "updatedAt": "2026-02-11T21:59:50.697Z",
        "project": "5f64bf72954a44005cc28c53",
        "live": false,
        "description": "ORD",
        "geometry": {
            "type": "Point",
            "coordinates": [
                -87.90691454986978,
                41.97895483910433
            ]
        },
        "geofences": [
            {
                "_id": "698cfb5b8b6de165a76b0c9a",
                "createdAt": "2026-02-11T21:57:47.467Z",
                "updatedAt": "2026-02-11T21:59:50.618Z",
                "live": false,
                "description": "Lobby",
                "metadata": {},
                "tag": "Lobby",
                "externalId": "Lobby",
                "type": "polygon",
                "geometryCenter": {
                    "type": "Point",
                    "coordinates": [
                        -87.90658744608658,
                        41.979057133832725
                    ]
                },
                "geometryRadius": 124,
                "disallowedPrecedingTagSubstrings": [],
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [
                        [
                            [
                                -87.90669732475371,
                                41.980178751312486
                            ],
                            [
                                -87.90717361615056,
                                41.97803907044686
                            ],
                            [
                                -87.90648513706793,
                                41.97794075296353
                            ],
                            [
                                -87.90599370637406,
                                41.98006996060805
                            ],
                            [
                                -87.90669732475371,
                                41.980178751312486
                            ]
                        ]
                    ]
                },
                "ip": [],
                "enabled": true
            }
        ],
        "beacons": [
            {
                "_id": "698cfbc86f337ba540a6a037",
                "createdAt": "2026-02-11T21:59:36.213Z",
                "updatedAt": "2026-02-11T22:02:07.867Z",
                "live": false,
                "description": "DEB7A751-58E9-470C-B02F-E0A0E0CB131D",
                "tag": "DEB7A751-58E9-470C-B02F-E0A0E0CB131D",
                "externalId": "DEB7A751-58E9-470C-B02F-E0A0E0CB131D",
                "metadata": {},
                "enabled": true,
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        -87.90648679100048,
                        41.97960296270185
                    ]
                },
                "type": "ibeacon",
                "uuid": "DEB7A751-58E9-470C-B02F-E0A0E0CB131D",
                "major": "0",
                "minor": "0"
            },
            {
                "_id": "698cfbd66f337ba540a6a081",
                "createdAt": "2026-02-11T21:59:50.521Z",
                "updatedAt": "2026-02-11T22:00:14.077Z",
                "live": false,
                "description": "160C2FE2-0FA8-4A03-B31B-D772318C12F5",
                "tag": "160C2FE2-0FA8-4A03-B31B-D772318C12F5",
                "externalId": "160C2FE2-0FA8-4A03-B31B-D772318C12F5",
                "enabled": true,
                "geometry": {
                    "type": "Point",
                    "coordinates": [
                        -87.90654336444055,
                        41.97959174783844
                    ]
                },
                "type": "ibeacon",
                "uuid": "160C2FE2-0FA8-4A03-B31B-D772318C12F5",
                "major": "0",
                "minor": "0"
            }
        ],
        "floorplan": {
            "path": "sites/5f64bf72954a44005cc28c53/image.png",
            "mimeType": "image/png",
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [
                            -87.90807735712883,
                            41.98040809982566
                        ],
                        [
                            -87.9057516718326,
                            41.98040809982566
                        ],
                        [
                            -87.90575174261079,
                            41.97750157838301
                        ],
                        [
                            -87.90807742790696,
                            41.97750157838301
                        ],
                        [
                            -87.90807735712883,
                            41.98040809982566
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
                        "x": 617.2617900013412,
                        "y": 132.5493415537822,
                        "_id": "698cfb5b8b6de165a76b0ca3"
                    },
                    {
                        "x": 776.7210342341738,
                        "y": 167.7424746009925,
                        "_id": "698cfb5b8b6de165a76b0ca4"
                    }
                ],
                "measureLength": 36,
                "measureUnit": "m"
            }
        }
    }
}
"""
