//
//  HKClincalRecordSelector.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit
import HealthKit
import HealthKitUI





@available(iOS 12.0, *)
class HKClinicalRecordSelectorStep: ORKFormStep {
    
    
    override init(identifier: String) {
        
        super.init(identifier: identifier)
        self.text = "This is your health data stored on your device. Please select the category of records to submit"
        self.footnote = "Data requested is intended to be shared with Sync4Science"
        
        
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI(records: [HKClinicalRecordResult]) {
        
        let choices    = records.map { $0.textChoice() }
        let reviewChoices = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
        let items = ORKFormItem(identifier: "clinicalrecords", text: nil, answerFormat: reviewChoices)
        items.isOptional = true
        self.formItems = [items]
    }
    
    
    
    
    
}

extension HKClinicalRecordResult {
    
    func textChoice() -> ORKTextChoice {
        
        let clinicalType = HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: self.identifier))!.categoryDisplayName
        
        return ORKTextChoice(text: clinicalType, detailText: "Records:  #\(clinicalRecords?.count ?? 0)", value: identifier as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        
    }
    
}



extension HKClinicalType {
    
    var categoryDisplayName: String {
        
        switch HKClinicalTypeIdentifier(rawValue: identifier) {
        case .allergyRecord:
            return "Allergies"
        case .conditionRecord:
            return "Conditions"
        case .immunizationRecord:
            return "Immunizations"
        case .labResultRecord:
            return "Lab Results"
        case .medicationRecord:
            return "Medications"
        case .procedureRecord:
            return "Procedures"
        case .vitalSignRecord:
            return "Clinical Vitals"
        default:
            return identifier
        }
    }
}
