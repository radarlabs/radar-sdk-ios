//  Copyright © 2021 Radar Labs, Inc. All rights reserved.

import RadarSDK
import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var versionNumberLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionNumberLabel.text = "Radar SDK version \(Radar.sdkVersion)"
    }
    
}
