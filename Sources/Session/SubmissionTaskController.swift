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
//        self.delegate = session
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
            SMSubmissionConclusionStep(identifier: kSM_Submission_Completion, _title: "Submitted", _detailText: "Thank You"),
        ]
        
       
        super.init(identifier: "smartmarkers.submission.task", steps: steps)
        steps.forEach { (s) in
            s.task = self
        }
        
        let selector = ORKResultSelector(resultIdentifier: kSM_Submission_Consent)
        let declinedPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: selector, expectedAnswer: false)
        let progressSelector = ORKResultSelector(stepIdentifier: kSM_Submission_InProgress, resultIdentifier: kSM_Submission_Result)
        let errorPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: progressSelector, expectedAnswer: true)
        let errorPredicateNull = ORKResultPredicate.predicateForNilQuestionResult(with: progressSelector)
        let cancelledNoticeSkipPredicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: selector, expectedAnswer: true)

        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [errorPredicate, errorPredicateNull, declinedPredicate])
        
        let skipErrorStepRule =  ORKPredicateSkipStepNavigationRule(resultPredicate: compoundPredicate)
        setSkip(skipErrorStepRule, forStepIdentifier: kSM_Submission_Errors)

        let navigationRule = ORKPredicateSkipStepNavigationRule(resultPredicate: declinedPredicate)
        let navigationRule2 = ORKPredicateSkipStepNavigationRule(resultPredicate: cancelledNoticeSkipPredicate)

        setSkip(navigationRule, forStepIdentifier: kSM_Submission_InProgress)
        setSkip(navigationRule, forStepIdentifier: kSM_Submission_Completion)
        setSkip(navigationRule2, forStepIdentifier: kSM_Submission_Aborted)
        setStepModifier(SMSubmissionErrorNoticeModifier(), forStepIdentifier: kSM_Submission_Errors)
        setStepModifier(ReviewStepModifier(), forStepIdentifier: kSM_Submission_Review)
        setStepModifier(ConsentStepModifier(), forStepIdentifier: kSM_Submission_Consent)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func step(before step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        let previous = super.step(before: step, with: result)
        
        if previous?.identifier == kSM_Submission_InProgress {
            return self.step(withIdentifier: kSM_Submission_Consent)
        }
        
        return previous
    }
    
    
    public override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        let stp = super.step(after: step, with: result)
        
        if stp?.identifier == kSM_Submission_Errors {
            
        }
        
        if stp?.identifier == kSM_Submission_Consent {
         
        }
        
        return stp
    }
}





