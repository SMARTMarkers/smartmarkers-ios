//
//  HealthRecordAuthorizationStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/24/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import HealthKit
import ResearchKit


@available(iOS 12.0, *)
open class HealthRecordAuthorizationStep: ORKWaitStep {
    
    var clinicalTypes: Set<HKClinicalType> = []

    public init(identifier: String, requestedHealthRecordIdentifiers: [HKClinicalTypeIdentifier]?) {
        super.init(identifier: identifier)
        if let types = requestedHealthRecordIdentifiers {
            clinicalTypes = Set(types.map { HKObjectType.clinicalType(forIdentifier: HKClinicalTypeIdentifier(rawValue: $0.rawValue))!})
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    open override func stepViewControllerClass() -> AnyClass {
        return HealthRecordAuthorizationStepViewController.self
    }
    
}
open class HealthRecordAuthorizationStepViewController: ORKWaitStepViewController {
    
    var clinicalTypes: Set<HKClinicalType> {
        return waitStep.clinicalTypes
    }
    
    var waitStep: HealthRecordAuthorizationStep {
        return step as! HealthRecordAuthorizationStep
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
                        let dataResult = HealthRecordResult(clinicalType: ctype, records: records)
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
