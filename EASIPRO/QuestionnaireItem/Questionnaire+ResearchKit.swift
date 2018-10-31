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


extension Questionnaire : InstrumentProtocol {
    
    
    public func ip_generateSteps(callback: @escaping (([ORKStep]?, Error?) -> Void)) {
        callback(nil, nil)
    }
    
    
    public func ip_navigableRules(for steps: [ORKStep]?, callback: (([ORKStepNavigationRule]?, Error?) -> Void)) {
        
        callback(nil, nil)
    }
    
    
    public var ip_code: Coding? {
        return code?.first
    }
    
    
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))  {
        
        ip_genereteSteps { (steps, rules, error) in
            if let steps = steps {
                let uuid = UUID()
                let taskIdentifier = measure.prescribingResource?.resource?.pro_identifier ?? uuid.uuidString
                
                let task = PROTask(identifier: taskIdentifier, steps: steps)
                task.measure = measure
                rules?.forEach({ (rule, ids) in
                    ids.forEach({ (stepid) in
                        task.setNavigationRule(rule, forTriggerStepIdentifier: stepid)
                    })
                })
                let taskViewController = PROTaskViewController(task: task, taskRun: uuid)
                taskViewController.measure = measure
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
    
    
    public var ip_title :String {
        return ep_displayTitle()
    }
    
    public var ip_version: String? {
        return version?.string
    }
    
    public var ip_identifier: String {
        return id!.string
    }
    
    
    public func ip_genereteSteps(callback: @escaping ((_ steps: [ORKStep]?, _ rules: [ORKPredicateStepNavigationRule: [String]]?, _ error: Error?) -> Void)) {
        
        guard let items = self.item else {
            callback(nil, nil, nil)
            return
        }
        var steps = [ORKStep]()
        var rules = [ORKPredicateStepNavigationRule: [String]]()
        var conditionalItems = [QuestionnaireItem]()
        let group = DispatchGroup()
        for item in items {
            guard let type = item.type else {
                print("missed itemtype")
                continue
            }
            if item.enableWhen != nil {
                conditionalItems.append(item)
            }
            group.enter()
            item.rk_answerFormat(callback: { (answerFormat, error) in
                if let error = error {
                    print(error)
                }
                else {
                    switch type {
                    case .display:
                        let step = ORKInstructionStep(identifier: item.rk_Identifier())
                        step.detailText = item.rk_InstructionText()
                        step.title = item.rk_text()
                        steps.append(step)
                        break
                    case .choice, .openChoice, .boolean:
                        let step = ORKQuestionStep(identifier: item.rk_Identifier(), title: item.rk_text(), text: nil, answer: answerFormat)
                        steps.append(step)
                    case .group:
                        // ::: TODO
                        break
                    default:
                        break
                    }
                }
                group.leave()
            })
        }
        
    
        /*
        conditionalItems.forEach { (citem) in
            var predicates = [(NSPredicate, String)]()
            let questionIds = citem.enableWhen!.map { $0.question!.string }
            let destinationIdentifier = citem.rk_Identifier()
            citem.enableWhen!.forEach({ (condition) in
                let olderStep = condition.question!.string
                let resultSelector = ORKResultSelector(resultIdentifier: olderStep)
                var predicate : NSPredicate
                if let boolean = condition.answerBoolean {
                    predicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: boolean.bool)
                    predicates.append((predicate, destinationIdentifier))
                }
                else if let coding = condition.answerCoding {
                    
                    let value = coding.system!.absoluteString + kDelimiter + coding.code!.string
                    predicate = ORKResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: value as NSCoding & NSCopying & NSObjectProtocol)
                    predicates.append((predicate, destinationIdentifier))
                }
            })

        }
        */
        
        
        group.notify(queue: .main) {
            callback(steps, rules, nil)
        }
        
    }

    
}

extension QuestionnaireItem {
    
    
    public func rule() -> ORKStepNavigationRule? {
        
        guard let conditions = enableWhen else {
            return nil
        }
        
        let condition = conditions.first
        let resultSelector = ORKResultSelector(resultIdentifier: condition!.question!.string)
        let predicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        let rule = ORKPredicateStepNavigationRule(resultPredicatesAndDestinationStepIdentifiers: [(predicate, rk_Identifier())])
        return rule
    }
    
    
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


extension QuestionnaireItemEnableWhen {
    
    
    
    
    
    
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


