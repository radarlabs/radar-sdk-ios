//
//  ViewController.swift
//  SwiftAppWithCocoaPods
//
//  Created by Jason Tibbetts on 2/1/22.
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
