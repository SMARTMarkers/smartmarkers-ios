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
open class ClinicalRecordTaskViewController: InstrumentTaskViewController {
    
    public convenience init() {
        
        let steps : [ORKStep] = [
            ClinicalRecordRequestStep(identifier: ksm_step_authreview, title: "Access Request", text: "Please select the type of clinical data to request from your iPhone."),
            ClinicalRecordWaitStep(identifier: ksm_step_auth),
            ClinicalRecordSelectorStep(identifier: ksm_step_review),
            ORKCompletionStep(identifier: ksm_step_completion, _title: "Medical Record", _detailText: "Selected data is ready for submission")
        ]
        let task  = ORKNavigableOrderedTask(identifier: "sm.healthkit.task", steps: steps)
        self.init(task: task, taskRun: UUID())
        self.view.tintColor = UIColor.red
        task.setStepModifier(ClnicalRecordStepModifier(), forStepIdentifier: ksm_step_review)
        task.setStepModifier(ClinicalRecordAuthorizationStepModifier(), forStepIdentifier: ksm_step_auth)
        
    }
}



