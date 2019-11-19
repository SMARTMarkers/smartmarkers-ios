//
//  AdaptiveQuestionnaireTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class AdaptiveQuestionnaireTaskViewController: QuestionnaireTaskViewController {
    
    public var adaptiveServer: FHIRServer? {
        didSet {
            adaptTask.adaptiveServer = adaptiveServer
        }
    }
    
    public var adaptTask: AdaptiveQuestionnaireTask2 {
        return task as! AdaptiveQuestionnaireTask2
    }
    
    open override func stepViewControllerHasNextStep(_ stepViewController: ORKStepViewController) -> Bool {
        return stepViewController.step?.identifier != Step.Conclusion.rawValue
    }
    
    open override func stepViewControllerHasPreviousStep(_ stepViewController: ORKStepViewController) -> Bool {
        if stepViewController.step?.identifier == Step.Conclusion.rawValue || stepViewController.step?.identifier == Step.Introduction.rawValue {
            return false
        }
        return super.stepViewControllerHasPreviousStep(stepViewController)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    open override func stepViewControllerResultDidChange(_ stepViewController: ORKStepViewController) {
        super.stepViewControllerResultDidChange(stepViewController)
    }
    
    open override func stepViewController(_ stepViewController: ORKStepViewController, didFinishWith direction: ORKStepViewControllerNavigationDirection) {
        
        if direction == .reverse {
            self.adaptTask.stepBack()
            print("Stepping Back")
        }
        
        super.stepViewController(stepViewController, didFinishWith: direction)
    }
}



/*
open class AdaptiveQuestionnaireTaskViewController: ORKTaskViewController {
    
    
    public var measure: (TaskController)?
    
    let btnTitle_inSession            =   "Continue"
    let btnTitle_Conluded             =   "Done"
    let btnTitle_BeginSession         =   "Begin"
    let taskIdentifier: String
    
    var server: FHIRMinimalServer {
        return (task as! AdaptiveQuestionnaireTask).server
    }
    
    var questionnaire: Instrument {
        return (task as! AdaptiveQuestionnaireTask).adaptiveQuestionnaire!
    }

    required public init(questionnaire: Questionnaire, server: SMART.FHIRMinimalServer, _taskIdentifier: String, steps: [ORKStep]) {
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





public class AdaptiveQuestionnaireTask: ORKNavigableOrderedTask  {
    
    public var server: SMART.FHIRMinimalServer
    
    public var _responses = [QuestionnaireResponse]()
    
    var latestResponse: QuestionnaireResponse? {
        return _responses.last
    }
    
    public var adaptiveQuestionnaire: Questionnaire?
    
    public var expirationTime: DateTime?
    
    public var finisedTime: DateTime?
    
    public var dynamicResponse: QuestionnaireResponse?
    
    public var conclusionRule : ORKDirectStepNavigationRule {
        return  ORKDirectStepNavigationRule(destinationStepIdentifier: StepId.conclusion.rawValue)
    }
    
    public var conclusionStep: ORKCompletionStep? {
        return self.step(withIdentifier: StepId.conclusion.rawValue) as? ORKCompletionStep
    }
    
    required public init(instrument: Questionnaire, server: FHIRMinimalServer, steps: [ORKStep]) {
        /*
         todo:
         1. Add throws; Questionnaire should have adapt extension, else should throw.
         2. No need of Initializing a Server, that should come from `Questionnaire`.
         3. No need of Steps either,
         4. Add `var responses: [QuestionnaireResponse](); append every new incoming QR, discard step if not.
         so
         
         - init(questionnaire: Questionnaire) throws
 
         */
        self.adaptiveQuestionnaire = instrument
        self.server = server
        var steps = steps
        let instructions = "\(instrument.sm_title)\nThis is a computer adaptive test. All questions are mandatory. Results will be dispatched to the EHR"
        let introductionStep = ORKInstructionStep(identifier: StepId.introduction.rawValue, _title: "Starting Survey", _detailText: instructions)
        let conclusionStep = ORKCompletionStep(identifier: StepId.conclusion.rawValue)
        
        steps.insert(introductionStep, at: 0)
        steps.append(conclusionStep)
        super.init(identifier: instrument.sm_identifier!, steps: steps)

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

    @discardableResult
    func resultsBody(for result: ORKTaskResult, finishedStep: ORKStep?, questionnaireResponse:  QuestionnaireResponse?) -> QuestionnaireResponse? {
        
        if questionnaireResponse == nil {
            return try! QuestionnaireResponse.sm_AdaptiveQuestionnaireBody(contained: adaptiveQuestionnaire!)
        }
        guard let answered = finishedStep, let stepResult = result.stepResult(forStepIdentifier: answered.identifier) else {
            return nil
        }
        
        if let choiceResult = stepResult.results?.first as? ORKChoiceQuestionResult {
            if let answers = choiceResult.c3_responseItems() {
                if let _ = questionnaireResponse?.item?.filter({$0.linkId?.string == answered.identifier}).first {
                    print("already added")
                    return nil
                }
                let qrItem = QuestionnaireResponseItem()
                qrItem.linkId = answered.identifier.fhir_string
                qrItem.answer = answers
                if let q = questionnaireResponse?.contained?.first as? Questionnaire {
                    if let item = q.item?.filter({$0.linkId?.string == answered.identifier}).first {
                        qrItem.extension_fhir = item.extension_fhir
                    }
                }
                var dynamicItems = questionnaireResponse?.item ?? [QuestionnaireResponseItem]()
                dynamicItems.append(qrItem)
                questionnaireResponse?.item = dynamicItems
                return questionnaireResponse
            }
        }
        return nil
    }
    
    open func continueTo(_ to: ORKStep,_ from: ORKStep) {
        assignRule(ORKDirectStepNavigationRule(destinationStepIdentifier: to.identifier), for: from.identifier)
    }
    
    open func continueTo(_ toIdentifier: String,_ from: ORKStep) {
        assignRule(ORKDirectStepNavigationRule(destinationStepIdentifier: toIdentifier), for: from.identifier)
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
    
    open func concludeAfter(_ triggeringStep: String, response: QuestionnaireResponse?) {
        conclusionStep?.title = "Thank You"
        conclusionStep?.text  = "Survey Completed"
        conclusionStep?.detailText = resultReport(from: response)
        assignRule(conclusionRule, for: triggeringStep)
    }
    
    open func assignRule(_ rule: ORKStepNavigationRule, for triggeringStep: String) {
        self.setNavigationRule(rule, forTriggerStepIdentifier: triggeringStep)
    }
    
    open func configure(conclusion: ORKStep, with questionnaireResponse: QuestionnaireResponse?, result: ORKTaskResult?) {
        
    }
    
    override public func step(after step: ORKStep?, with result: ORKTaskResult) -> ORKStep? {

        guard let step = step else {
            return super.step(after: nil, with: result)
        }
 
        
        // First Step, initialize empty QuestionnaireResponse
        if step.identifier == StepId.introduction.rawValue, nil == dynamicResponse {
            dynamicResponse = try! QuestionnaireResponse.sm_AdaptiveQuestionnaireBody(contained: adaptiveQuestionnaire!)
        }
        
        // Last Step, nothing further
        if step.identifier == StepId.conclusion.rawValue {
            return nil
        }
        
        // Did Tap "Next Button"?
        if let lastResultStepIdentifer = result.results?.last?.identifier, step.identifier == lastResultStepIdentifer {
            dynamicResponse = resultsBody(for: result, finishedStep: step, questionnaireResponse: _responses.last)
            let semaphore = DispatchSemaphore(value: 0)
            print(try? dynamicResponse?.sm_jsonString() ?? "")
            adaptiveQuestionnaire?.next_q(server: server, questionnaireResponse: dynamicResponse, callback: { [weak self] (resource, error) in
                    if let resource = resource as? QuestionnaireResponse {
                        self?._responses.append(resource)
                        self?.dynamicResponse = resource
                        if self?.dynamicResponse?.status == QuestionnaireResponseStatus.completed {
                            self?.concludeAfter(step.identifier, response: self?.dynamicResponse)
                        }
                        else if self?.dynamicResponse?.status == QuestionnaireResponseStatus.inProgress {
                            if let questionnaire = resource.contained?.first as? Questionnaire {
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
*/

