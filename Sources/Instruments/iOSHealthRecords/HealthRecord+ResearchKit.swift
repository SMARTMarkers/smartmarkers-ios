//
//  HealthKit+ResearchKit.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 6/25/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import HealthKit
import ResearchKit



@available(iOS 12.0, *)
extension HKClinicalTypeIdentifier {
    
    public static var ImmunizationChoice: ORKTextChoice {
        return ORKTextChoice(text: "Immunizations", detailText: "Requests Immunization data from HealthKit" , value: HKClinicalTypeIdentifier.immunizationRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var LabRecordChoice: ORKTextChoice {
        return ORKTextChoice(text: "Lab Tests", detailText: "Requests Laboratory Tests data from HealthKit" , value: HKClinicalTypeIdentifier.labResultRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var MedicationsChoice: ORKTextChoice {

        return ORKTextChoice(text: "Medications", detailText: "Requests Medications data from HealthKit" , value: HKClinicalTypeIdentifier.medicationRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var AllergiesChoice: ORKTextChoice {
        
        return ORKTextChoice(text: "Allergies", detailText: "Requests Allergies data from HealthKit" , value: HKClinicalTypeIdentifier.allergyRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var ConditionsChoice: ORKTextChoice {
        
        return ORKTextChoice(text: "Conditions", detailText: "Requests Conditions data from HealthKit" , value: HKClinicalTypeIdentifier.conditionRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var ProceduresChoice: ORKTextChoice {
        
        return ORKTextChoice(text: "Procedures", detailText: "Requests Procedures data from HealthKit" , value: HKClinicalTypeIdentifier.procedureRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    public static var vitalSignsChoice: ORKTextChoice {
        
        return ORKTextChoice(text: "Vital Signs", detailText: "Requests Vital Signs data from HealthKit" , value: HKClinicalTypeIdentifier.vitalSignRecord as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
    }
    
    // as ORKBodyItem
    
    public var asBodyItem: ORKBodyItem {
        
        let str = HKObjectType.clinicalType(forIdentifier: self)!.categoryDisplayName
        return ORKBodyItem(text: str, detailText: nil, image: nil, learnMoreItem: nil, bodyItemStyle: .bulletPoint)
    }
    
}

extension HealthRecordResult {
    
    func textChoice() -> ORKTextChoice {
        
        let clinicalType = HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: identifier))!.categoryDisplayName
        
        return ORKTextChoice(text: clinicalType, detailText: "Records:  #\(records?.count ?? 0)", value: identifier as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        
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
