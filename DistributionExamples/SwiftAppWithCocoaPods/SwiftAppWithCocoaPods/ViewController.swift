//
//  ViewController.swift
//  SwiftAppWithCocoaPods
//
//  Copyright © 2022 Radar Labs, Inc. All rights reserved.
//

import RadarSDK
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var versionNumberLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let radarBundle = Bundle(for: Radar.self)
        let versionString = radarBundle.infoDictionary!["CFBundleShortVersionString"] as? String
        versionNumberLabel.text = versionString
    }

}
