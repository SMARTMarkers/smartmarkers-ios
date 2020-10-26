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
    
    public required init(settings: [String:String]?) {
        
        let introductionTitle = settings?["introduction_title"] ?? ClinicalRecordTaskViewController.Introduction_Title
        let introductionText  = settings?["introduction_text"] ?? ClinicalRecordTaskViewController.Introduction_Text
        let completionTitle   = settings?["completion_step_title"] ?? ClinicalRecordTaskViewController.Completion_Title
        let completionText    = settings?["completion_step_text"] ?? ClinicalRecordTaskViewController.Completion_Text
        
        let steps : [ORKStep] = [
               ClinicalRecordRequestStep(identifier: ksm_step_authreview, title: introductionTitle, text: introductionText),
               ClinicalRecordWaitStep(identifier: ksm_step_auth),
               ClinicalRecordSelectorStep(identifier: ksm_step_review),
               ORKCompletionStep(identifier: ksm_step_completion, _title: completionTitle, _detailText: completionText)
           ]
       let task  = ORKNavigableOrderedTask(identifier: "sm.healthkit.task", steps: steps)
       super.init(task: task, taskRun: UUID())
       self.view.tintColor = UIColor.red
       task.setStepModifier(ClnicalRecordStepModifier(), forStepIdentifier: ksm_step_review)
       task.setStepModifier(ClinicalRecordAuthorizationStepModifier(), forStepIdentifier: ksm_step_auth)
		task.setSkip(ClnicalRecordNotFoundNavigationRule(), forStepIdentifier: ksm_step_review)
		task.setStepModifier(ClinicalRecordNotFoundStepModifier(), forStepIdentifier: ksm_step_completion)
           
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Defaults
    static let Introduction_Title  =   "Access Request"
    static let Introduction_Text   =   "Please select the type of clinical data to request from your iPhone."
    static let Completion_Title    =   "Health Records"
    static let Completion_Text     =   "Task completed"
}






