//
//  SMTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 12/13/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit


open class InstrumentTaskViewController: ORKTaskViewController {
    
    // Workaround for a bug in presenting `ORKTaskViewController` on iOS 13+
    public override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            navigationBar.prefersLargeTitles = false
        }
    }
}
