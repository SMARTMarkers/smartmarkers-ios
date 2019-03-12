//
//  AdaptiveQuestionnaireTaskViewController.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

public enum StepId: String {
    case introduction = "introductionStep"
    case conclusion   = "conclusionStep"
}


open class AdaptiveQuestionnaireTaskViewController: ORKTaskViewController {
    
    
    public var measure: (PROMeasure)?
    
    
    let btnTitle_inSession            =   "Continue"
    let btnTitle_Conluded             =   "Done"
    let btnTitle_BeginSession         =   "Begin"
    let taskIdentifier: String
    
    var server: FHIRMinimalServer {
        return (task as! AdaptiveQuestionnaireTask).server
    }
    
    var questionnaire: InstrumentProtocol {
        return (task as! AdaptiveQuestionnaireTask).questionnaire!
    }
    
    required public init(questionnaire: QuestionnaireR4, server: SMART.FHIRMinimalServer, _taskIdentifier: String, steps: [ORKStep]) {
        self.taskIdentifier = _taskIdentifier
        let task = AdaptiveQuestionnaireTask(instrument: questionnaire, server: server, steps: steps)
        super.init(task: task, taskRun:  UUID(uuidString: taskIdentifier))
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func stepViewControllerHasNextStep(_ stepViewController: ORKStepViewController) -> Bool {
        return stepViewController.step?.identifier != StepId.conclusion.rawValue
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.showsProgressInNavigationBar = false
    }
}

extension SMART.Extension {
    
    convenience init(_ url: FHIRURL, _ dateTime: DateTime?) {
        self.init(url: url)
        self.valueDateTime = dateTime
    }
}



public class AdaptiveQuestionnaireTask: ORKNavigableOrderedTask  {
    
    public var server: SMART.FHIRMinimalServer
    
    public var questionnaire: QuestionnaireR4?
    
    public var expirationTime: DateTime?
    
    public var finisedTime: DateTime?
    
    public var dynamicResponse: QuestionnaireResponseR4?
    
    public var conclusionRule : ORKDirectStepNavigationRule {
        return  ORKDirectStepNavigationRule(destinationStepIdentifier: StepId.conclusion.rawValue)
    }
    
    public var conclusionStep: ORKCompletionStep? {
        return self.step(withIdentifier: StepId.conclusion.rawValue) as? ORKCompletionStep
    }
    
    required public init(instrument: QuestionnaireR4, server: FHIRMinimalServer, steps: [ORKStep]) {
        self.questionnaire = instrument
        self.server = server
        var steps = steps
        let instructions = "\(instrument.ip_title)\nThis is a computer adaptive test. All questions are mandatory. Results will be dispatched to the EHR"
        let introductionStep = ORKInstructionStep(identifier: StepId.introduction.rawValue, _title: "Starting Survey", _detailText: instructions)
        let conclusionStep = ORKCompletionStep(identifier: StepId.conclusion.rawValue)
        
        steps.insert(introductionStep, at: 0)
        steps.append(conclusionStep)
        super.init(identifier: instrument.ip_identifier, steps: steps)

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    @discardableResult
    func resultsBody(for result: ORKTaskResult, finishedStep: ORKStep?, questionnaireResponse: inout QuestionnaireResponseR4?) -> Bool {
        
        guard let finished = finishedStep, let stepResult = result.stepResult(forStepIdentifier: finished.identifier) else {
            return false
        }
        
        if let choiceResult = stepResult.results?.first as? ORKChoiceQuestionResult {
            if let answers = choiceResult.c3_responseItems() {
                if let _ = questionnaireResponse?.item?.filter({$0.linkId?.string == finished.identifier}).first {
                    print("already added")
                    return false
                }
                let qrItem = QuestionnaireResponseItem()
                qrItem.linkId = finished.identifier.fhir_string
                qrItem.answer = answers
                if let q = questionnaireResponse?.contained?.first as? QuestionnaireR4 {
                    if let item = q.item?.filter({$0.linkId?.string == finished.identifier}).first {
                        qrItem.extension_fhir = item.extension_fhir
                    }
                }
                var dynamicItems = questionnaireResponse?.item ?? [QuestionnaireResponseItem]()
                dynamicItems.append(qrItem)
                questionnaireResponse?.item = dynamicItems
                return true
            }
        }
        return true
    }
    
    open func continueTo(_ to: ORKStep,_ from: ORKStep) {
        assignRule(ORKDirectStepNavigationRule(destinationStepIdentifier: to.identifier), for: from.identifier)
    }
    
    open func continueTo(_ toIdentifier: String,_ from: ORKStep) {
        assignRule(ORKDirectStepNavigationRule(destinationStepIdentifier: toIdentifier), for: from.identifier)
    }
    
    open func resultReport(from response: QuestionnaireResponseR4?) -> String? {
        if let scores = response?.extensions(forURI: kStructureDefinition_QuestionnaireResponseScores)?.first {
            let theta = scores.extensions(forURI: kStructureDefinition_QuestionnaireResponseScoresTheta)?.first?.valueDecimal
            let deviation = scores.extensions(forURI: kStructureDefinition_QuestionnaireResponseScoresStandardError)?.first?.valueDecimal
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
    
    open func concludeAfter(_ triggeringStep: String, response: QuestionnaireResponseR4?) {
        conclusionStep?.title = "Thank You"
        conclusionStep?.text  = "Survey Completed"
        conclusionStep?.detailText = resultReport(from: response)
        assignRule(conclusionRule, for: triggeringStep)
    }
    
    open func assignRule(_ rule: ORKStepNavigationRule, for triggeringStep: String) {
        self.setNavigationRule(rule, forTriggerStepIdentifier: triggeringStep)
    }
    
    open func configure(conclusion: ORKStep, with questionnaireResponse: QuestionnaireResponseR4?, result: ORKTaskResult?) {
        
    }
    
    override public func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {

        guard let step = step else {
            return super.step(after: nil, with: result)
        }

        // First Step, initialize empty QuestionnaireResponse
        if step.identifier == StepId.introduction.rawValue, nil == dynamicResponse {
            dynamicResponse = try! QuestionnaireResponseR4.sm_body(contained: questionnaire!)
        }
        
        // Last Step, nothing further
        if step.identifier == StepId.conclusion.rawValue {
            return nil
        }
        
        // Did Tap "Next Button"?
        if let lastResultStepIdentifer = result.results?.last?.identifier, step.identifier == lastResultStepIdentifer {
            resultsBody(for: result, finishedStep: step, questionnaireResponse: &dynamicResponse)
            let semaphore = DispatchSemaphore(value: 0)
            try? dynamicResponse?.prettyPrint()
            questionnaire?.next_q(server: server, questionnaireResponse: dynamicResponse, callback: { [weak self] (resource, error) in
                    if let resource = resource as? QuestionnaireResponseR4 {
                        self?.dynamicResponse = resource
                        if self?.dynamicResponse?.status == QuestionnaireResponseStatus.completed {
                            self?.concludeAfter(step.identifier, response: self?.dynamicResponse)
                        }
                        else if self?.dynamicResponse?.status == QuestionnaireResponseStatus.inProgress {
                            if let questionnaire = resource.contained?.first as? QuestionnaireR4 {
                                questionnaire.status = PublicationStatus.active
                                if let linkId = questionnaire.item?.first?.linkId?.string {
                                    self?.continueTo(linkId, step)
                                }
                            }
                        }
                    }
                    else {
                        // TODO: find a strategy to handle this!
                        fatalError("no resource :\(String(describing: error?.description))")
                    }
                semaphore.signal()
            })
            semaphore.wait()
        }
        return super.step(after: step, with: result)
    }
    
    
    
    
    
    
    
    
    

   
    
    
}




