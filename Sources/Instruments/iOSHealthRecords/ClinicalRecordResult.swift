//
//  HKClinicalRecordResult.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import HealthKit
import ResearchKit

class ClinicalRecordResult: ORKResult {
    
    var clinicalRecords: [HKClinicalRecord]?
    
    required convenience init(clinicalType: HKClinicalType, records: [HKClinicalRecord]) {
        self.init(identifier: clinicalType.identifier)
        self.clinicalRecords = records
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(clinicalRecords as Any, forKey: "clinicalRecords")
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone) as! ClinicalRecordResult
        result.clinicalRecords = clinicalRecords
        return result
    }
}


class ClnicalRecordNotFoundNavigationRule: ORKSkipStepNavigationRule {
	
	override func stepShouldSkip(with taskResult: ORKTaskResult) -> Bool {
		
		if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [ClinicalRecordResult] {
			
			let filtered = dataResults.filter { (result) -> Bool in
				return (result.clinicalRecords?.count ?? 0 > 0)
			}
			return filtered.count == 0
        }
		
		return true
	}
	
}

class ClinicalRecordNotFoundStepModifier: ORKStepModifier {
	
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let completionStep = step as? ORKCompletionStep else {
            return
        }
		
		if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [ClinicalRecordResult] {
			
			let filtered = dataResults.filter { (result) -> Bool in
				return (result.clinicalRecords?.count ?? 0 > 0)
			}
			
			if filtered.count > 0 {
				completionStep.text = "Health records retrieved."
			}
			else {
				completionStep.text = "Health records could not be retrieved.\n\nThis maybe due to lack of data in the health app or access permission not granted."
			}
        }
		
	}
}

class ClnicalRecordStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let stp = step as? ClinicalRecordSelectorStep else {
            return
        }
        
        
        if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [ClinicalRecordResult] {
            stp.title = "Health Records"
            stp.setupUI(records: dataResults)
        }

        
    }
    
}

class ClinicalRecordAuthorizationStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let authResults = taskResult.stepResult(forStepIdentifier: ksm_step_authreview), let slf = step as? ClinicalRecordWaitStep else {
            return
        }
        
        let choiceResults = authResults.results!.first as! ORKChoiceQuestionResult
        let clinicalTypes = (choiceResults.choiceAnswers as! [String]).map { HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0))!}
        slf.clinicalTypes = Set(clinicalTypes)
    }
}
