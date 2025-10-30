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
            "branchName": "shicheng/sites-floorplan-upload",
            "sha": "3cbb4d8a4281bc9e5aa01045914ca921c7b42adc",
            "date": "2025-10-30T18:46:46.938Z"
        }
    },
    "site": {
        "_id": "6903b9c005b29017743c2abe",
        "createdAt": "2025-10-30T19:17:20.659Z",
        "updatedAt": "2025-10-30T19:17:20.659Z",
        "project": "6862db1b39ce329dacc255a6",
        "live": false,
        "description": "office",
        "geometry": {
            "type": "Point",
            "coordinates": [
                -73.99118515629965,
                40.73840359056395
            ]
        },
        "geofences": [],
        "beacons": [],
        "floorplan": {
            "path": "sites/6862db1b39ce329dacc255a6/office-floor.png",
            "mimeType": "image/png",
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [
                            -73.99150620164346,
                            40.73892501612322
                        ],
                        [
                            -73.9904300357224,
                            40.73846444938788
                        ],
                        [
                            -73.99086410875327,
                            40.73788216500468
                        ],
                        [
                            -73.9919402768769,
                            40.73834273405509
                        ],
                        [
                            -73.99150620164346,
                            40.73892501612322
                        ]
                    ]
                ]
            },
            "calibration": {
                "imageSize": {
                    "width": 1588,
                    "height": 1134
                },
                "calibrationPoints": [
                    {
                        "x": 735.0784122242648,
                        "y": 390.0156776577819,
                        "_id": "6903b9c005b29017743c2abf"
                    },
                    {
                        "x": 731.941157322304,
                        "y": 470.0156776577819,
                        "_id": "6903b9c005b29017743c2ac0"
                    }
                ],
                "measureLength": 5.25,
                "measureUnit": "m"
            }
        }
    }
}
"""
