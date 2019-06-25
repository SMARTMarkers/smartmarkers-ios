//
//  HKClinicalRecordTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import ResearchKit
import HealthKit


let ksm_step_authreview         = "smartmarkers.step.healthkit.authorizationreview"
let ksm_step_auth               = "smartmarkers.step.healthkit.authorization"
let ksm_step_review             = "smartmarkers.step.healthkit.review"
let ksm_step_submission         = "smartmarkers.step.healthkit.submission"
let ksm_step_completion         = "smartmarkers.step.healthkit.completion"

@available(iOS 12.0, *)
open class HKClinicalRecordTaskViewController: ORKTaskViewController {
    
    public convenience init() {
        
        
        let steps : [ORKStep] = [
            HKClinicalRecordRequestStep(identifier: ksm_step_authreview),
            HKClinicalRecordWaitStep(identifier: ksm_step_auth),
            HKClinicalRecordSelectorStep(identifier: ksm_step_review),
            HKClinicalRecordSubmissionStep(identifier: ksm_step_submission), //wait
            ORKCompletionStep(identifier: ksm_step_completion, _title: "Submitted", _detailText: "Selected data has been submitted")
        ]
        let task  = ORKNavigableOrderedTask(identifier: "sm.healthkit.task", steps: steps)
        self.init(task: task, taskRun: UUID())
        self.view.tintColor = UIColor.red
        task.setStepModifier(HKClnicalStepModifier(), forStepIdentifier: ksm_step_review)
        task.setStepModifier(HKClinicalAuthorizationStepModifier(), forStepIdentifier: ksm_step_auth)
    }
}



