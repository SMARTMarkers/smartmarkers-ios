//
//  HKClinicalRecordStep.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import HealthKit


@available(iOS 12.0, *)
open class HKClinicalRecordRequestStep: ORKQuestionStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.question = "Please select the type of clinical data push to your Research team"
        let choices = [
            ORKTextChoice(text: "Immunizations", detailText: "Requests Immunization data from HealthKit", value: "Immunizations" as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            ORKTextChoice(text: "Laboratory Tests", detailText: "Requests Lab tests data from HealthKit", value: "Laboratory" as NSCoding & NSCopying & NSObjectProtocol, exclusive: false),
            
            ORKTextChoice(text: "Medications", detailText: "Requests Medication list data from HealthKit", value: "Medications" as NSCoding & NSCopying & NSObjectProtocol, exclusive: false)
        ]
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
        self.answerFormat = answerFormat
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return HKClinicalRecordRequestStepViewController.self
    }
    
    open func authorization() {
        
       
        
    }
    
}

open class HKClinicalRecordWaitStep: ORKWaitStep {
    
    
}

open class HKClinicalRecordRequestStepViewController: ORKQuestionStepViewController {
    
    
    public var stp: HKClinicalRecordRequestStep {
        return step as! HKClinicalRecordRequestStep
    }
    
    
    open override func goForward() {
        if let rs = result?.results?.first as? ORKChoiceQuestionResult {
            guard let medicationsType = HKObjectType.clinicalType(forIdentifier: .medicationRecord), let labs = HKObjectType.clinicalType(forIdentifier: .labResultRecord) else {
                
                return
            }
            let store = HKHealthStore()
            store.requestAuthorization(toShare: nil, read: [medicationsType, labs]) { (success, error ) in
                if (success) {
                    print("successfully shared")
                }
                super.goForward()
            }
        }
    }
    
}


open class HKDeidentifyStep: ORKQuestionStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.question = "De-identify as per HIPPA guidelines?"
        self.answerFormat = ORKAnswerFormat.booleanAnswerFormat()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


@available(iOS 12.0, *)
open class HKClinicalRecordTaskViewController: ORKTaskViewController {
    
    var resourceTypes: [HKClinicalTypeIdentifier]?
    
    
    public convenience init() {
        let steps : [ORKStep] = [
            HKClinicalRecordRequestStep(identifier: "sm.healthkit.request.step"),
            HKDeidentifyStep(identifier: "sm.healthkit.deidentification")
            
        ]
        let task  = ORKOrderedTask(identifier: "sm.healthkit.task", steps: steps)
        self.init(task: task, taskRun: UUID())
        self.title = "Clinical Record"

    }
    
}



