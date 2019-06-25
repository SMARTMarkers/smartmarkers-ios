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

class HKClinicalRecordResult: ORKResult {
    
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
        let result = super.copy(with: zone) as! HKClinicalRecordResult
        result.clinicalRecords = clinicalRecords
        return result
    }
}




class HKClnicalStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let stp = step as? HKClinicalRecordSelectorStep else {
            return
        }
        
        
        if let dataResults = taskResult.stepResult(forStepIdentifier: ksm_step_auth)?.results as? [HKClinicalRecordResult] {
            stp.title = "Verify Submission"
            stp.setupUI(records: dataResults)
        }

        
    }
    
}

class HKClinicalAuthorizationStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let authResults = taskResult.stepResult(forStepIdentifier: ksm_step_authreview), let slf = step as? HKClinicalRecordWaitStep else {
            return
        }
        
        let choiceResults = authResults.results!.first as! ORKChoiceQuestionResult
        let clinicalTypes = (choiceResults.choiceAnswers as! [String]).map { HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0))!}
        slf.clinicalTypes = Set(clinicalTypes)
    }
}
