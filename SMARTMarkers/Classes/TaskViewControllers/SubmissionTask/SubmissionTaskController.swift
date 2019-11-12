//
//  SubmissionTaskController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


let kSM_Submission_Review       = "smartmarkers.submission.review"
let kSM_Submission_Consent      = "smartmarkers.submission.consent"
let kSM_Submission_Completion   = "smartmarkers.submission.completion"
let kSM_Submission_InProgress   = "smartmarkers.submission.inprogress"
let kSM_Submission_Errors       = "smartmarkers.submission.errors"
let kSM_Submission_Aborted      = "smartmarkers.submission.aborted"
let kSM_Submission_Result       = "smartmarkers.submission.result"


open class SubmissionTaskController: ORKTaskViewController {
    
    public init(_ session: SessionController,  requiresConsent: Bool = false) {
        
        let task = SubmissionTask(session)
        super.init(task: task, taskRun: UUID())
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


public final class SubmissionTask: ORKNavigableOrderedTask {
    
    
    unowned let session: SessionController
    
    public init(_ session: SessionController) {
        
        self.session = session
        
        let steps = [
            SMSubmissionPermitStep(identifier: kSM_Submission_Review),
            SMSubmissionServerNotice(identifier: kSM_Submission_Consent),
            ORKInstructionStep(identifier: kSM_Submission_Aborted, _title: "Cancelled", _detailText: "Submission was aborted"),
            SMSubmissionInProgressStep(identifier: kSM_Submission_InProgress),
            SMSubmissionErrorNotice(identifier: kSM_Submission_Errors),
            ORKCompletionStep(identifier: kSM_Submission_Completion, _title: "Submitted", _detailText: "Thank You"),

        ]
        
       
        super.init(identifier: "sm.submission.task", steps: steps)
        steps.forEach { (s) in
            s.task = self
        }
        
        let selector = ORKResultSelector(resultIdentifier: kSM_Submission_Consent)
        let resultPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: selector, expectedAnswer: false)
        let progressSelector = ORKResultSelector(stepIdentifier: kSM_Submission_InProgress, resultIdentifier: kSM_Submission_Result)
        let errorPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: progressSelector, expectedAnswer: true)
        let errorPredicateNull = ORKResultPredicate.predicateForNilQuestionResult(with: progressSelector)
        let cancelledNoticeSkipPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: selector, expectedAnswer: true)

        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [errorPredicate, errorPredicateNull, resultPredicate])
        
        let skipErrorStepRule =  ORKPredicateSkipStepNavigationRule(resultPredicate: compoundPredicate)
        setSkip(skipErrorStepRule, forStepIdentifier: kSM_Submission_Errors)



        let navigationRule = ORKPredicateSkipStepNavigationRule(resultPredicate: resultPredicate)
        let navigationRule2 = ORKPredicateSkipStepNavigationRule(resultPredicate: cancelledNoticeSkipPredicate)

        setSkip(navigationRule, forStepIdentifier: kSM_Submission_InProgress)
        setSkip(navigationRule, forStepIdentifier: kSM_Submission_Completion)
        setSkip(navigationRule2, forStepIdentifier: kSM_Submission_Aborted)
        setStepModifier(SMSubmissionErrorNoticeModifier(), forStepIdentifier: kSM_Submission_Errors)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    public override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        let stp = super.step(after: step, with: result)
        
        if stp?.identifier == kSM_Submission_Review {
            (stp as! SMSubmissionPermitStep).formItems = session.measures.map ({ $0.sm_asFormItem() })
        }
        
        if stp?.identifier == kSM_Submission_Errors {
            
        }
        
        
        if stp?.identifier == kSM_Submission_Consent {
             let submissionNotice = "Selected reports will be submitted to: \(session.server!.name ?? "FHIR Server") at \(session.server!.baseURL.host ?? "")"
            (stp as! SMSubmissionServerNotice).text = submissionNotice
        }
        
        return stp
    }
}





