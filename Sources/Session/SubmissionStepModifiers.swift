//
//  StepModifiers.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/25/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit


class ReviewStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        let task = step.task as! SubmissionTask
        (step as! SMSubmissionPermitStep).formItems = task.session.tasks.map ({ $0.sm_asFormItem() })
    }
}

class ConsentStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        guard let selected = taskResult.stepResult(forStepIdentifier: kSM_Submission_Review) else {
            return
        }
        let task = step.task as! SubmissionTask
        if let selectedTasksIdentifiers = selected.results?.compactMap({ (result) -> String? in
            let result = result as! ORKChoiceQuestionResult
            if let taskIds = result.answer as? [String] {
                return taskIds.first
            }
            return nil
        }) {
            let submissionNotice = "\(selectedTasksIdentifiers.count) Selected\n\nWill be submitted to: \(task.session.server!.name ?? "FHIR Server") at \(task.session.server!.baseURL.host ?? ""). Proceed?"
            step.text = submissionNotice
        }
    }
}

open class SMSubmissionErrorNoticeModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
     
        let task = step.task as! SubmissionTask
        if let result = taskResult.stepResult(forStepIdentifier: kSM_Submission_InProgress)?.results?.last as? ORKBooleanQuestionResult {
            let skip = result.booleanAnswer == 1
            if !skip {
                let rule = ORKDirectStepNavigationRule(destinationStepIdentifier: kSM_Submission_Review)
                task.setNavigationRule(rule, forTriggerStepIdentifier: step.identifier)
                
            }
        }
    }
    
}


extension TaskController {
    
    func sm_asFormItem() -> ORKFormItem {
        
        let reportChoices = reports?.sm_asTextChoiceAnswerFormat()
        let formItem = ORKFormItem(identifier: instrument?.sm_title ?? "#", text: instrument?.sm_title, answerFormat: reportChoices)
        formItem.isOptional = true
        return formItem
    }
}

extension Reports {
    
    func sm_asTextChoiceAnswerFormat() -> ORKTextChoiceAnswerFormat? {
        
        guard hasReportsToSubmit else {
            return nil
        }
        
        var choices = [ORKTextChoice]()
        for sub in reportsToSubmit() ?? [] {
            
            guard let bundle = sub.bundle else { continue }
            
            let title = "#\(bundle.sm_resourceCount()) health data resources"
            let content = """
            \(bundle.sm_ContentSummary() ?? "")
            
            Status: \(sub.status.rawValue)
            Task Id: \(sub.taskId)
            
            """
            
            let choice = ORKTextChoice(
                text: title,
                detailText: content, 
                value: sub.taskId as NSCoding & NSCopying & NSObjectProtocol,
                exclusive: false
            )
            
            choices.append(choice)
        }
        
        return ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: choices)
    }
}
