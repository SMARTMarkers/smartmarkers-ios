//
//  QuestionStep.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/5/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

extension SMART.Questionnaire : InstrumentProtocol {
    
    public var ip_title: String {
        return sm_displayTitle() ?? "--No title--"
    }
    
    public var ip_identifier: String {
        return id!.string
    }
    
    public var ip_code: Coding? {
        return code?.first
    }
    
    public var ip_version: String? {
        return version?.string
    }
    
    public var ip_resultingFhirResourceType: [PROFhirLinkRelationship]? {
        return [PROFhirLinkRelationship(QuestionnaireResponse.self, ["questionnaire": self.id!.string])]

    }
    
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))  {
        
        sm_genereteSteps { (steps, rulestupples, error) in
            if let steps = steps {
                let uuid = UUID()

                let taskIdentifier = measure.request?.rq_identifier ?? uuid.uuidString
                let task = ORKNavigableOrderedTask(identifier: taskIdentifier, steps: steps)
                rulestupples?.forEach({ (rule, linkId) in
                    task.setSkip(rule, forStepIdentifier: linkId)
                })
                
                let taskViewController = QuestionnaireTaskViewController(task: task, taskRun: uuid)
                callback(taskViewController, nil)
            }
            else {
                callback(nil, nil)
            }
        }
    }
    
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        
        guard let taskResults = result.results as? [ORKStepResult] else {
            print("No results found")
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
}
