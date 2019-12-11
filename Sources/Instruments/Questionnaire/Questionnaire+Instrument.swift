//
//  Questionnaire+Instrument.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 7/5/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


/**
 Conformance of FHIR `Questionnaire` with `Instrument` Protocol
 
 Manages transformation of Questionnaire into ResearchKit steps (`ORKStep`). Applicable for both– adaptive and static questionnaires
 The receiver initializes
 */
extension SMART.Questionnaire: Instrument {
    
    public var sm_title: String {
        get { return sm_displayTitle() ?? "FHIR Questionnaire" }
        set { }
    }
    
    public var sm_type: InstrumentCategoryType? {
        set {  }
        get { return  .Survey }
    }
    
    public var sm_identifier: String? {
        set {  }
        get { return id?.string }
    }
    
    public var sm_code: Coding? {
        set {  }
        get { return code?.first }
    }
    
    public var sm_version: String? {
        set {  }
        get { return version?.string }
    }
    
    public var sm_publisher: String? {
        set {  }
        get { return publisher?.string }
    }
    
    public var sm_reportSearchOptions: [FHIRReportOptions]? {
        set { }
        get {
            var searchParam = [String]()
            
            if let id = id?.string {
                searchParam.append(id)
            }
            
            if let url = url?.absoluteString {
                searchParam.append(url)
            }
            
            if !searchParam.isEmpty {
                return [
                    FHIRReportOptions(QuestionnaireResponse.self, ["questionnaire": searchParam.joined(separator: ",")])
                ]
            }
            return nil
        }
    }
    
    
    public func sm_taskController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        
        if item == nil, let srv = _server, let iden = id?.string  {
            let semaphore = DispatchSemaphore(value: 0)
            Questionnaire.read(iden, server: srv, options: [.lenient]) { (resource, error) in
                self.item = (resource as? Questionnaire)?.item
                semaphore.signal()
            }
            semaphore.wait()
        }
    
        sm_genereteSteps { (steps, rulestupples, error) in
            
            if var steps = steps {
                let uuid = UUID()
                let taskIdentifier = uuid.uuidString
     
                
                /*
                 TODO
                 Should check adaptive based on presence of SDC Extension.
                */
                let adaptive = (self._server is AdaptiveServer)
                if adaptive {
                    let task = AdaptiveQuestionnaireTask(identifier: taskIdentifier, steps: steps, adaptiveQuestionnaire: self, adaptiveServer: self._server)
                    rulestupples?.forEach({ (rule, linkId) in
                        task.setSkip(rule, forStepIdentifier: linkId)
                    })
                    let taskViewController = AdaptiveQuestionnaireTaskViewController(task: task, taskRun: uuid)
                    callback(taskViewController, nil)

                }
                else {
                    let (introStep, completedStep) = self.introductionAndConclusionSteps()
                    steps.insert(introStep, at: 0)
                    steps.append(completedStep)
                    let task = ORKNavigableOrderedTask(identifier: taskIdentifier, steps: steps)
                    rulestupples?.forEach({ (rule, linkId) in
                        task.setSkip(rule, forStepIdentifier: linkId)
                    })
                    let taskViewController = ORKTaskViewController(task: task, taskRun: uuid)
                    callback(taskViewController, nil)
                }
            }
            else {
                callback(nil, error?.first)
            }
        }
    }
    
    
    public func sm_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        // AdaptiveQuestionnaire?
        // Should be determined from the Questionnaire.
        // For now: lets check if task is Adaptive.
        // Fall back would be to go as usual, derive QR from `ORKTaskResult`
        if let task = task as? AdaptiveQuestionnaireTask, let questionnaireResponse = task.currentResponse {
            return SMART.Bundle.sm_with([questionnaireResponse])
        }
        
        guard let taskResults = result.results as? [ORKStepResult] else {
            return nil
        }
        
        
        var itemGroups = [QuestionnaireResponseItem]()
        for result in taskResults {
            if let item = result.responseItems(for: self, task: task) {
                itemGroups.append(contentsOf: item)
            }
        }
        
        let answer = QuestionnaireResponse(status: .completed)
        answer.questionnaire = (url != nil) ? FHIRCanonical(url!.absoluteString) : nil
        answer.authored = DateTime.now
        answer.item = itemGroups
        
        let qrId = "urn:uuid:\(UUID().uuidString)"
        let entry = BundleEntry()
        entry.fullUrl = FHIRURL(qrId)
        entry.resource = answer
        entry.request = BundleEntryRequest(method: .POST, url: FHIRURL("QuestionnaireResponse")!)
        let bundle = SMART.Bundle()
        bundle.entry = [entry]
        bundle.type = BundleType.transaction
        return bundle
        
    }
    
    
    
    
}



extension Questionnaire {
    
    /// Best possible title for the Questionnaire
    func sm_displayTitle() -> String? {
        
        if let name     = name { return name.string }
        if let title    = title    {    return title.string }
        
        if let codes = self.code {
            for code in codes {
                if let display = code.display {
                    return display.string
                }
            }
        }
        
        if let identifier = self.identifier {
            for iden in identifier {
                if let value = iden.value {
                    return value.string
                }
            }
        }
        
        return self.id?.string
    }
    
    func isAdaptive() -> Bool {
        return false
    }
}
