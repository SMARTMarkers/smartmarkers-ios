//
//  HKClinicalRecordStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/19/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import HealthKit





@available(iOS 12.0, *)
open class ClinicalRecordWaitStep: ORKWaitStep {
    
    var clinicalTypes: Set<HKClinicalType> = []

    open override func stepViewControllerClass() -> AnyClass {
        return ClinicalRecordAuthorizationStepViewController.self
    }
    
}
open class ClinicalRecordAuthorizationStepViewController: ORKWaitStepViewController {
    
    var clinicalTypes: Set<HKClinicalType> {
        return waitStep.clinicalTypes
    }
    
    var waitStep: ClinicalRecordWaitStep {
        return step as! ClinicalRecordWaitStep
    }

    var data: [HKSample]?
    let store = HKHealthStore()
    
    
    open override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        store.getRequestStatusForAuthorization(toShare: Set(), read: clinicalTypes) { (status, error) in
            if status == .shouldRequest {
                self.requestAuthorization()
            } else {
                DispatchQueue.main.async {
                    self.updateText("Fetching clinical data from HealthKit")
                    self.runQuery()
                }
            }
        }
    }
    
    func requestAuthorization(_ sender: AnyObject? = nil) {
        store.requestAuthorization(toShare: nil, read: clinicalTypes) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    self.updateText("Authorization complete\nFetching clinical records from Health app")
                    self.runQuery()
                }
                else {
                    self.handleError(error)
                }
            }
            
        }
    }
    func runQuery() {
        
        let group = DispatchGroup()
        for ctype in clinicalTypes {
            group.enter()
            let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            
            let query = HKSampleQuery(sampleType: ctype, predicate: nil, limit: 100, sortDescriptors: sortDescriptors) {(_, samplesOrNil, error) in
                DispatchQueue.main.async {
                    guard let samples = samplesOrNil else {
                        //TODO: handle error, goForward will still be called.
                        self.handleError(error)
                        return
                    }
                    if let records = samples as? [HKClinicalRecord] {
                        let dataResult = ClinicalRecordResult(clinicalType: ctype, records: records)
                        self.addResult(dataResult)
                    }
                }
                group.leave()
            }
            store.execute(query)
        }
        
        group.notify(queue: .main) {
            self.goForward()
        }
        
        
    }
    
    // MARK: -
    
    /// Set up an alert controller to display messages to the user as needed.
    func present(message: String, titled title: String, goBack: Bool = false) {
        dispatchPrecondition(condition: .onQueue(.main))
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let handler : ((UIAlertAction) -> Void)? = goBack ? { alert in
            self.goBackward()
            } : nil
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
        present(alertController, animated: true)
    }
    
    func handleError(_ error: Error?) {
        present(message: error?.localizedDescription ?? "Unknown Error", titled: "Error", goBack: true)
        
    }
    

    
}



@available(iOS 12.0, *)
open class ClinicalRecordDeidentifyStep: ORKQuestionStep {
    
    public override init(identifier: String) {
        super.init(identifier: identifier)
        self.title = "Deidentification"
        self.text = "Identifiable elements will be obfuscated as per HIPPA guidelines before submission."
        self.question = "Should deidentify?"
        self.answerFormat = ORKAnswerFormat.booleanAnswerFormat()
		self.isOptional = false

    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



@available(iOS 12.0, *)
open class ClinicalRecordRequestStep: ORKQuestionStep {
    
    public required init(identifier: String, title: String?, text: String?) {
        super.init(identifier: identifier)
        self.text = text
        self.title = title
        self.question = "Select the type for clinical record"
		self.isOptional = false
        let choices = [
            HKClinicalTypeIdentifier.vitalSignsChoice,
            HKClinicalTypeIdentifier.ImmunizationChoice,
            HKClinicalTypeIdentifier.AllergiesChoice,
            HKClinicalTypeIdentifier.LabRecordChoice,
            HKClinicalTypeIdentifier.ConditionsChoice,
            HKClinicalTypeIdentifier.MedicationsChoice,
            HKClinicalTypeIdentifier.ProceduresChoice
        ]
        let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
        self.answerFormat = answerFormat
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
