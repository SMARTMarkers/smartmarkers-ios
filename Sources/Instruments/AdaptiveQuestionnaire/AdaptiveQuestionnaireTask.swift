//
//  AdaptiveOperation.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


public enum Step: String, CustomStringConvertible {
    
    case Introduction
    case Conclusion
    public var description: String {
        return self.rawValue
    }
}

open class AdaptiveQuestionnaireTask: ORKNavigableOrderedTask {
    
    public let adaptiveQuestionnaire: Questionnaire
    
    public var adaptiveServer: FHIRServer?
    
    lazy var answers: [QuestionnaireResponse] =  {
        return [QuestionnaireResponse]()
    }()
    
    var currentResponse: QuestionnaireResponse? {
        return answers.last
    }
    
    public internal(set) var completedFlag: Bool = false
    
    var shouldSubmitResponse = true
    
    var currentQuestionLinkId: String? {
        let q = answers.last?.contained?.first as? Questionnaire
        return q?.item?.first?.linkId?.string
    }
    
    public func stepBack() {
        answers.removeLast()
        shouldSubmitResponse = false
        
    }
    
    public required init(identifier: String, steps: [ORKStep], adaptiveQuestionnaire: Questionnaire, adaptiveServer: FHIRServer?) {
        
        let title = adaptiveQuestionnaire.sm_displayTitle() ?? "Survey #\(adaptiveQuestionnaire.sm_identifier ?? "")"
        let instructions = "\(title)\n\nThis is a computer adaptive test."
        let introductionStep = ORKInstructionStep(identifier: Step.Introduction.rawValue, _title: "Starting Survey", _detailText: instructions)
        let conclusionStep = ORKCompletionStep(identifier: Step.Conclusion.rawValue)
        
        var steps = steps
        steps.insert(introductionStep, at: 0)
        steps.append(conclusionStep)
        self.adaptiveQuestionnaire = adaptiveQuestionnaire
        self.adaptiveServer = adaptiveServer
        super.init(identifier: identifier, steps: steps)
        self.steps.forEach({ (step) in
            step.task = self
        })
        setStepModifier(AdaptiveConclusionStepModifier(), forStepIdentifier: Step.Conclusion.rawValue)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        

        guard shouldSubmitResponse else {
            shouldSubmitResponse = true
            return super.step(after:step, with: result)
        }
        
        guard let sourceStep = step, sourceStep.identifier != Step.Conclusion.rawValue else {
            return super.step(after:step, with: result)
        }
        
        guard let stepResult = result.stepResult(forStepIdentifier: sourceStep.identifier) else {
            return super.step(after: step, with: result)
        }

        let responseItem = stepResult.responseItems(for: adaptiveQuestionnaire, task: self)?.first
        
        // responseItem can only be nil for the Intro step.
        // Other fetches cannot be nil!
        
        if sourceStep.identifier != Step.Introduction.rawValue {
            if responseItem == nil {
                return super.step(after: step, with: result)
            }
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        adaptiveQuestionnaire.next_q2(server: adaptiveServer!, answer: responseItem, forQuestionnaireItemLinkId: sourceStep.identifier, options: [.lenient], for: currentResponse) { [weak self] (new_qresponse, error) in
            if let new = new_qresponse {
                self?.answers.append(new)
                if new.status == .completed {
                    self?.continueTo(Step.Conclusion.rawValue, sourceStep)
                    self?.completedFlag = true
                }
                else {
                    if let newLinkId = self?.currentQuestionLinkId {
                        self?.continueTo(newLinkId, sourceStep)
                    }
                }
            }
            semaphore.signal()
        }
        semaphore.wait()

        return super.step(after: step, with: result)
    }
    
    open func continueTo(_ toIdentifier: String,_ from: ORKStep) {
        setNavigationRule(ORKDirectStepNavigationRule(destinationStepIdentifier: toIdentifier), forTriggerStepIdentifier: from.identifier)
    }
    
    open func resultReport(from response: QuestionnaireResponse?) -> String? {
        if let scores = response?.extensions(forURI: kSD_QuestionnaireResponseScores)?.first {
            let theta = scores.extensions(forURI: kSD_QuestionnaireResponseScoresTheta)?.first?.valueDecimal
            let deviation = scores.extensions(forURI: kSD_QuestionnaireResponseScoresStandardError)?.first?.valueDecimal
            if let theta = theta, let deviation = deviation {
                let tscore = String(round((Double(theta.decimal.description)! * 10) + 50.0))
                let standardError =  String(round(Double(deviation.decimal.description)! * 10))
                return """
                T-Score: \(tscore)
                StdErr:  \(standardError)
                """
            }
        }
        return nil
    }
    
    
}




class AdaptiveConclusionStepModifier: ORKStepModifier {
    
    override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        let task = step.task as! AdaptiveQuestionnaireTask
        let score = task.resultReport(from: task.currentResponse) ?? ""
        step.title = "Completed"
        step.text =  "Survey concluded, Thank you.\n\n\(score)"
    }
}


