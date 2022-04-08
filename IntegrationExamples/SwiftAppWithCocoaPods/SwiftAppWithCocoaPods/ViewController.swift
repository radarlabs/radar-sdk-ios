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

        versionNumberLabel.text = Radar.sdkVersion
    }

}
