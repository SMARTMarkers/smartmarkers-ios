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
    
    
    weak var session: SessionController?
    
    
    public init(_ session: SessionController) {
        
        self.session = session
        
  
        let permit = SMSubmissionPermitStep(identifier: ksm_step_review)
        permit.isOptional = false

        let steps = [
            permit,
            SMSubmissionServerNotice(identifier: ksm_step_submission),
            SMSubmissionInProgressStep(identifier: "submitting"),
            ORKCompletionStep(identifier: "completion", _title: "Submitted", _detailText: "Thank You")
        ]
       
        
        super.init(identifier: "sm.submission.task", steps: steps)
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        let stp = super.step(after: step, with: result)
        
        if stp?.identifier == ksm_step_review {
            (stp as! SMSubmissionPermitStep).formItems = self.session!.measures.map ({ $0.sm_asFormItem() })
        }
        
        
        
        if stp?.identifier == ksm_step_submission {
             let submissionNotice = "## Selected reports will be submitted to: \(session!.server!.name ?? "") at \(session!.server!.baseURL.host ?? "")"
            (stp as! SMSubmissionServerNotice).text = submissionNotice
        }
        return stp
    }
}





