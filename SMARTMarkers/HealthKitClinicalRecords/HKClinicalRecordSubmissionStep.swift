//
//  HKClinicalRecordSubmissionStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import HealthKit
import SMART


class HKClinicalRecordSubmissionStep: ORKWaitStep {
    
    override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Submitting"
        self.text = "Please wait\nData is being submitted..."
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return HKClinicalRecordSubmissionStepViewController.self
    }
}

class HKClinicalRecordSubmissionStepViewController: ORKWaitStepViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateText("Please wait\nData is being submitted...")
        submitData()
        goForward()
    }
    
    
    func submitData() {
        sleep(3)
    }
    
}
