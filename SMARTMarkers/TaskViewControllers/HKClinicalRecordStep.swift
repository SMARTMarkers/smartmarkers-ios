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
    
    
    
    open func authorization() {
        
       
        
    }
    
}

@available(iOS 12.0, *)
open class HKClinicalRecordWaitStep: ORKWaitStep {
    
    open override func stepViewControllerClass() -> AnyClass {
        return HKClinicalRecordAuthorizationStepViewController.self
    }
    
}
open class HKClinicalRecordAuthorizationStepViewController: ORKWaitStepViewController {
    
    var clinicalTypeIdentifier: [HKClinicalTypeIdentifier]! = [.medicationRecord,.labResultRecord]
    
    lazy var clinicalTypes: Set<HKClinicalType> = {
        return Set(self.clinicalTypeIdentifier.map { HKObjectType.clinicalType(forIdentifier: $0)! })
    }()

    let store = HKHealthStore()
    
    open override func viewDidAppear(_ animated: Bool) {
        
        print(clinicalTypeIdentifier)
        print(clinicalTypes)
        

        store.requestAuthorization(toShare: nil, read:  clinicalTypes) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    self.checkStatus()
                }
                else {
                    self.updateText("Unable to complete authorization")
                    self.goBackward()
                }
            }
            
        }
    }
    
    func checkStatus() {
        var authorized = 0
        
        let allergyQuery = HKSampleQuery(sampleType: clinicalTypes.first!, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let actualSamples = samples else {
                // Handle the error here.
                print("*** An error occurred: \(error?.localizedDescription ?? "nil") ***")
                return
            }
            
            let allergySamples = actualSamples as? [HKClinicalRecord]
            print(allergySamples)
        }
        
        store.execute(allergyQuery)
        
        
        for type in clinicalTypes {

            let status = store.authorizationStatus(for: type)
            if status == .notDetermined {
                print("not")
            }
            
            if status == .sharingAuthorized {
                print("allowed")
                authorized += 1
            }
            
            if status == .sharingDenied {
                print("denied")
            }
            
        }
        
    }
    
}



@available(iOS 12.0, *)
open class HKDeidentifyStep: ORKQuestionStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Deidentification"
        self.text = "Identifiable elements will be obfuscated as per HIPPA guidelines before submission."
        self.question = "Should deidentify?"
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
            HKClinicalRecordWaitStep(identifier: "smartmarkers.step.healthkit.authorization"),
            HKDeidentifyStep(identifier: "sm.healthkit.deidentification"),
            HKClinicalRecordWaitStep(identifier: "smartmarkers.step.healthkit.query")
        ]
        let task  = ORKOrderedTask(identifier: "sm.healthkit.task", steps: steps)
        self.init(task: task, taskRun: UUID())
        self.title = "Clinical Record"

    }
    
}



