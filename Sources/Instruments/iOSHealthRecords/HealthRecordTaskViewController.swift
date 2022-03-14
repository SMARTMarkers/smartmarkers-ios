//
//  HKClinicalRecordTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import ResearchKit
import HealthKit


let ksm_healthrecord_step_introduction       = "smartmarkers.step.healthkit.introduction"
let ksm_healthrecord_step_authorization      = "smartmarkers.step.healthkit.authorization"
let ksm_healthrecord_step_review             = "smartmarkers.step.healthkit.review"
let ksm_healthrecord_step_completion         = "smartmarkers.step.healthkit.completion"

@available(iOS 12.0, *)
open class HealthRecordTaskViewController: InstrumentTaskViewController {
    
    public required init(settings: [String:Any]?) {
        
        // Settings
        let introductionTitle = settings?["introduction_title"] as? String ?? HealthRecordTaskViewController.Introduction_Title
        let introductionText = settings?["introduction_text"] as? String ?? HealthRecordTaskViewController.Introduction_Title
		let learnMoreText		= settings?["learnmore_text"] as? String ?? nil
        let completionTitle   = settings?["completion_step_title"] as? String ?? HealthRecordTaskViewController.Completion_Title
        let completionText    = settings?["completion_step_text"] as? String ?? HealthRecordTaskViewController.Completion_Text
        let requestedClinicalRecordTypes = settings?["requestedClinicalRecordTypes"] as? [HKClinicalTypeIdentifier] ?? nil
		let learnMoreBodyItems = settings?["learnMoreBodyItems"] as? [ORKBodyItem] ?? nil
        
        
		var steps = [ORKStep]()

		let introStep = HealthRecordIntroductionStep.Create(identifier: ksm_healthrecord_step_introduction,
                                                            title: introductionTitle,
                                                            text: introductionText,
															learnMoreBulletText: "Learn more about data being requested",
															learnMoreText: "The following data will be requested and retrieved (if found) from the Health app",
															learnMoreTitle: nil,
															bodyItems: learnMoreBodyItems,
                                                            requestedClinicalRecordTypes: requestedClinicalRecordTypes)

		steps.append(introStep)
        
        // Authorization
        let authorizationStep = HealthRecordAuthorizationStep(identifier: ksm_healthrecord_step_authorization,
                                                              requestedHealthRecordIdentifiers: requestedClinicalRecordTypes)
		steps.append(authorizationStep)
        
        // Review
		if settings?["skipSelectorStep"] as? Bool ?? false != true {
			let reviewStep = HealthRecordReviewStep(identifier: ksm_healthrecord_step_review)
			steps.append(reviewStep)
		}
        
        
        // Conclusion
        let conclusionStep = HealthRecordConclusionStep(identifier: ksm_healthrecord_step_completion, _title: completionTitle, _detailText: completionText)
		steps.append(conclusionStep)
        
       let task  = ORKNavigableOrderedTask(identifier: "sm.healthkit.task", steps: steps)
		

        if (requestedClinicalRecordTypes == nil || requestedClinicalRecordTypes!.isEmpty) {
            task.setStepModifier(HealthRecordTypeSelectionStepModifier(), forStepIdentifier: ksm_healthrecord_step_authorization)
        }
        task.setStepModifier(HealthRecordResultDisplaySelectedStepModifier(), forStepIdentifier: ksm_healthrecord_step_review)
        task.setSkip(HealthRecordNotFoundNavigationRule(), forStepIdentifier: ksm_healthrecord_step_review)
        task.setStepModifier(HealthRecordNotFoundStepModifier(), forStepIdentifier: ksm_healthrecord_step_completion)
        super.init(task: task, taskRun: UUID())

           
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    // Defaults
    static let Introduction_Title       =   "Access Request"
    static let Introduction_Text        =   "Please select the type of clinical data to request from your iPhone."
    static let Introduction_Text_Alt    =   "The following type of health records will be requested from your Health app"
    static let Introduction_Learnmore   =   "Learn more about this specific step"
    static let Completion_Title         =   "Health Records"
    static let Completion_Text          =   ""
}






