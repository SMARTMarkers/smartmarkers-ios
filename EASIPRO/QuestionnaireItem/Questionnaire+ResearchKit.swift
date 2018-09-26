//
//  Questionnaire+Extensions.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/3/18.     
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


extension Questionnaire : InstrumentProtocol     {
    
    public var rk_code: Coding? {
        return code?.first
    }
    
    
    
    public func rk_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))  {
        
        rk_generateSteps { (steps, error) in
            if let steps = steps {
                let uuid = UUID()
                let taskIdentifier = measure.prescribingResource?.resource?.pro_identifier ?? uuid.uuidString
                let task = PROTask(identifier: taskIdentifier, steps: steps)
                task.measure = measure
                let taskViewController = PROTaskViewController(task: task, taskRun: uuid)
                taskViewController.measure = measure
                callback(taskViewController, nil)
            }
            else {
                callback(nil, nil)
            }
        }
    }
    
    
    
    
    public func rk_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {

        guard let taskResults = result.results as? [ORKStepResult] else {
            print("No results found")
            return nil
        }
        
        var itemGroups = [QuestionnaireResponseItem]()
        for result in taskResults {
            if let item = result.c3_responseItems(for: task) {
                itemGroups.append(contentsOf: item)
            }
        }
        
        let questionnaire = Reference()
        questionnaire.reference = FHIRString(result.identifier)
        let answer = QuestionnaireResponse(status: .completed)
        answer.questionnaire = questionnaire
        answer.authored = DateTime.now
        answer.questionnaire?.reference?.string = "Questionnaire/\(id!.string)"
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
    
    
    
    
    public var rk_title :String {
        return ep_displayTitle()
    }
    
    public var rk_version: String? {
        return version?.string
    }
    
    
    
    
    public var rk_identifier: String {
        return id!.string
    }
    
    
    public func rk_taskController(for measure: PROMeasure, callback: @escaping ((RKTaskViewControllerProtocol?, Error?) -> Void)) {
        rk_generateSteps { (steps, error) in
            if let steps = steps {
                let uuid = UUID()
                let taskIdentifier = measure.prescribingResource?.resource?.pro_identifier ?? uuid.uuidString
                let task = PROTask(identifier: taskIdentifier, steps: steps)
                task.measure = measure
                let taskViewController = PROTaskViewController(task: task, taskRun: uuid)
                taskViewController.measure = measure
                callback(taskViewController, nil)
            }
            else {
                callback(nil, nil)
            }
        }
    }
    
    
    public func rk_generateSteps(callback:  @escaping ((_ steps : [ORKStep]?, _ error: Error?) -> Void)) {
        
        guard let items = self.item else {
            callback(nil, nil)
            return
        }
        
        var steps =  [ORKStep]()
        let group = DispatchGroup()
        
        
        for item in items {
            
            guard let type = item.type else {
                callback(nil, nil)
                return
            }
            
            switch type {
            case .openChoice, .choice, .boolean:
                    group.enter()
                    PROQuestionStep.initialise(item) { (step, error) in
                        if let step = step { steps.append(step) }
                        group.leave()
                    }
            case .group:
                group.enter()
                PROFormStep.initialise(item) { (step, error) in
                    if let step = step { steps.append(step) }
                    group.leave()
                }
            case .display:
                group.enter()
                PROInstructionStep.initialise(item) { (step, error) in
                    if let step = step { steps.append(step) }
                    group.leave()
                }
            case .question:
                break
                
            case .decimal:
                break
                
            case .integer:
                break
                
            case .date:
                break
                
            case .dateTime:
                break
                
            case .time:
                break
                
            case .string:
                break
                
            case .text:
                break
                
            case .url:
                break
                
            case .openChoice:
                break
                
            case .attachment:
                break
                
            case .reference:
                break
                
            case .quantity:
                break
                
            default:
                break
       
            }
            
        }
        
//        .global(qos: .default)
        group.notify(queue: .main) {
            callback(steps, nil)
        }
        
  
        
        
    }

    
}

extension QuestionnaireItem {
    
    public func rk_text() -> String? {
        return text?.localized
    }
    
    public func rk_InstructionText() -> String? {
        return extensions(forURI: kStructureDefinition_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    public func rk_HelpText() -> String? {
        return extensions(forURI: kStructureDefinition_QuestionnaireHelp)?.first?.valueString?.localized
    }
    
    
    public func rk_Identifier() -> String {
        return linkId?.string ?? UUID().uuidString
    }
    
    public func rk_answerFormat(callback: @escaping (_ anser: ORKAnswerFormat?, _ error :Error?) -> Void) {
        
        guard let type = type else {
            print("item type missing")
            callback(nil, nil)
            return
        }
        
        switch type {
        case .display:   callback(nil, nil)
        case .boolean:   callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
        case .date:      callback(ORKAnswerFormat.dateAnswerFormat(), nil)
        case .dateTime:  callback(ORKAnswerFormat.dateTime(), nil)
        case .time:      callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
        case .string:    callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .url:       callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .choice:
            if let answerValueSet = options {
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                answerValueSet.resolve(ValueSet.self, callback: { (choices) in
                    if let choices = choices, let af = choices.rk_choiceAnswerFormat(style: style) {
                        callback(af, nil)
                    } else {
                        callback(nil, nil)
                    }
                })
            } else { callback (nil, nil) }
        default:
            print("could not deduce Answer type")
            callback(nil, nil)
        }
    }
    
    
}

let kDefaultSystem      = "CHOICESYSTEM"
let kDefaultAnserCode   = "ANSWERCODE"
let kDelimiter          = "|"

extension ValueSet {
    
    
    
    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKAnswerFormat? {
        
        var choices = [ORKTextChoice]()
        
        if let expansion = expansion?.contains {
            for option in expansion {
                let system = option.system?.absoluteString ?? kDefaultSystem
                let code = option.code?.string ?? kDefaultAnserCode
                let value = system + kDelimiter + code
                let answerChoice = ORKTextChoice(text: option.display_localized ?? code, detailText: nil, value: value as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
                choices.append(answerChoice)
            }
        }
        
        else if let includes = compose?.include {
            for include in includes {
                let system = include.system?.absoluteString ?? kDefaultSystem
                include.concept?.forEach({ (concept) in
                    let code = concept.code?.string ?? kDefaultAnserCode
                    let value = system + kDelimiter + code
                    let answerChoice = ORKTextChoice(text: concept.display_localized ?? code, value: value as NSCoding & NSCopying & NSObjectProtocol)
                    choices.append(answerChoice)
                })
            }
            
        }
        
        if choices.count > 0 {
            return ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
        }
        
        return nil
        
    }
}


    /*
        Modified with Permission From C3-PRO
        Created by Pascal Pfiffner on 6/26/15.
        Copyright © 2015 Boston Children's Hospital. All rights reserved.
        https://github.com/C3-PRO
    */


extension ORKStepResult {

    
    func c3_responseItems(for task: ORKTask) -> [QuestionnaireResponseItem]? {
        
        guard let results = results else {
            return nil
        }
        
        var items = [QuestionnaireResponseItem]()
        for result in results {
            if let result = result as? ORKQuestionResult {
                print(result.identifier)
                if let question = task.step!(withIdentifier: result.identifier) as? ORKQuestionStep, let answers = result.c3_responseItemAnswers(from: question) {
                    
                    let responseItem = QuestionnaireResponseItem(linkId: result.identifier.fhir_string)
                    print(question.title)
                    responseItem.text = question.title?.fhir_string
                    responseItem.answer = answers
                    items.append(responseItem)
                    
                    
                    print(answers)
                }
               
                
            }
        }
        
        return items.count > 0 ? items : nil
    }
    

}

extension ORKQuestionResult {
    
    func c3_responseItemAnswers(from step: ORKQuestionStep?) -> [QuestionnaireResponseItemAnswer]? {
        
        if let slf = self as? ORKChoiceQuestionResult {
            return slf.c3_responseItems()
        }
        
        return nil
    }
}

extension ORKChoiceQuestionResult {
    
    func c3_responseItems() -> [QuestionnaireResponseItemAnswer]? {
        
        guard let choices = choiceAnswers as? [String] else {
            if let _ = choiceAnswers {
                print("exp choice question results to be strings")
            }
            return nil
        }
        
        var answers = [QuestionnaireResponseItemAnswer]()
        for choice in choices {
            let answer = QuestionnaireResponseItemAnswer()
            let splat = choice.components(separatedBy: kDelimiter)
            let system = splat[0]
            let code = (splat.count > 1) ? splat[1..<splat.endIndex].joined(separator: String(kDelimiter)) : kDefaultAnserCode
            answer.valueCoding = Coding()
            answer.valueCoding!.system = FHIRURL(system)
            answer.valueCoding!.code = FHIRString(code)
            answers.append(answer)
        }
        return answers
    }
}

