//
//  HealthRecordStepModifiers.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/24/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import HealthKit


class HealthRecordNotFoundNavigationRule: ORKSkipStepNavigationRule {
    
    override func stepShouldSkip(with taskResult: ORKTaskResult) -> Bool {
        
        if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_healthrecord_step_authorization)?.results as? [HealthRecordResult] {
            
            let filtered = dataResults.filter { (result) -> Bool in
                return (result.records?.count ?? 0 > 0)
            }
            return filtered.count == 0
        }
        
        return true
    }
}

class HealthRecordNotFoundStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let completionStep = step as? ORKCompletionStep else {
            return
        }
        
        if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_healthrecord_step_authorization)?.results as? [HealthRecordResult] {
            
            let filtered = dataResults.filter { (result) -> Bool in
                return (result.records?.count ?? 0 > 0)
            }
            
            if filtered.count > 0 {
                completionStep.title = "Health records retrieved"
				completionStep.bodyItems = nil
            }
            else {
                completionStep.title = "Health records were not retrieved"
				completionStep.bodyItems = [
					ORKBodyItem(text: "This maybe due to lack of data in the health app or access permission not granted." ,
								detailText: nil,
								image: nil,
								learnMoreItem: HealthRecords.linkInstructionsAsLearnMoreItem(),
								bodyItemStyle: .text)
				]
            }
        }
        
    }
}


class HealthRecordResultDisplaySelectedStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let stp = step as? HealthRecordReviewStep else {
            return
        }
        
        if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_healthrecord_step_authorization)?.results as? [HealthRecordResult] {
            stp.title = "Health Records"
            stp.setupUI(records: dataResults)
        }
    }
}



class HealthRecordTypeSelectionStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let authResults = taskResult.stepResult(forStepIdentifier: ksm_healthrecord_step_introduction), let slf = step as? HealthRecordAuthorizationStep else {
            return
        }
        
        let choiceResults = authResults.results!.first as! ORKChoiceQuestionResult
        let clinicalTypes = (choiceResults.choiceAnswers as! [String]).map { HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0))!}
        slf.clinicalTypes = Set(clinicalTypes)
    }
}
