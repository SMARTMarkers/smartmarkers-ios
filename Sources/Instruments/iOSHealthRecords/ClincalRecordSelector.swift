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
class ClinicalRecordSelectorStep: ORKFormStep {
    
    
    override init(identifier: String) {
        
        super.init(identifier: identifier)
        self.footnote = ""
		self.isOptional = false
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI(records: [ClinicalRecordResult]) {
		
		// filter Clinical Record Result which has have atleast more than one health record
		
		let filtered = records.filter { (result) -> Bool in
			return (result.clinicalRecords?.count ?? 0 > 0)
		}
		
		if filtered.count > 0 {
			self.text = "The following set(s) of health records have been retrieved from your iPhone (Health app)\nPlease select data for import into the app"
			let choices    = filtered.map { $0.textChoice() }
			let reviewChoices = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
			let items = ORKFormItem(identifier: "clinicalrecords", text: nil, answerFormat: reviewChoices)
			  items.isOptional = true
			self.formItems = [items]
		}
		else {
			self.text = "Health Records could not be retrieved"
			self.formItems = nil
		}
		
      
    }
    
    
    
    
    
}

extension ClinicalRecordResult {
    
    func textChoice() -> ORKTextChoice {
        
        let clinicalType = HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: identifier))!.categoryDisplayName
        
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
            return "Vitals Signs"
        default:
            return identifier
        }
    }
}
