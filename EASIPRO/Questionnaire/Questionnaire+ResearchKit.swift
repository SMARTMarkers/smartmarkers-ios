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

public typealias RuleTupple = (ORKPredicateSkipStepNavigationRule, String)
public typealias StepsCallback = (_ steps: [ORKStep]?, _ rules: [RuleTupple]?, _ error: Error?) -> Void


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
        
        ip_genereteSteps { (steps, rulestupples, error) in
            if let steps = steps {
                let uuid = UUID()
                let taskIdentifier = measure.prescribingResource?.resource?.pro_identifier ?? uuid.uuidString
                
                let task = PROTask(identifier: taskIdentifier, steps: steps)
                task.measure = measure
                rulestupples?.forEach({ (rule, linkId) in
                    task.setSkip(rule, forStepIdentifier: linkId)
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
    
    
    public func ip_genereteSteps(callback: @escaping StepsCallback) {
        
        guard let items = self.item else {
            callback(nil, nil, nil)
            return
        }
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        let group = DispatchGroup()
        for item in items {
            group.enter()
            item.generateSteps(callback: { (steps, rules, error) in
                if let error = error {
                    print(error as Any)
                }
                else {
                    if let steps = steps {
                        nsteps.append(contentsOf: steps)
                    }
                    if let rules = rules {
                        nrules.append(contentsOf: rules)
                    }
                }
                group.leave()
            })
        }
        
        group.notify(queue: .main) {
            callback(nsteps.isEmpty ? nil:nsteps, nrules, nil)
        }
        
    }

    
}

extension QuestionnaireItem {
    
    
    public func generateSteps(callback: @escaping StepsCallback) {
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var conditionalItems = [QuestionnaireItem]()
        let group = DispatchGroup()
        
        if self.enableWhen != nil {
                conditionalItems.append(self)
        }
        group.enter()
        self.rk_answerFormat(callback: { (answerFormat, error) in
            if let error = error {
                print(error)
            }
            else {
                switch self.type! {
                case .display:
                    let step = ORKInstructionStep(identifier: self.rk_Identifier())
                    step.detailText = self.rk_InstructionText()
                    step.title = self.rk_text()
                    nsteps.append(step)
                    break
                    
                case .choice, .openChoice, .boolean, .date, .dateTime, .time, .string, .integer:
                    let step = ORKQuestionStep(identifier: self.rk_Identifier(), title: self.rk_text(), text: nil, answer: answerFormat)
                    nsteps.append(step)
                    break
                    
                case .group:
                    if let subItems = self.item {
                        print("case:.group, steps present")
                        for subitem in subItems {
                            subitem.generateSteps(callback: { (steps, rules, err ) in
                                if let error = error {
                                    print(error as Any)
                                }
                                else {
                                    if let steps = steps {
                                        nsteps.append(contentsOf: steps)
                                    }
                                    if let rules = rules {
                                        nrules.append(contentsOf: rules)
                                    }
                                }
                            })
                        }
                    }
                    break
                default:
                    break
                }
            }
            group.leave()
        })
        
        conditionalItems.forEach { (citem) in
            
            let conditions = citem.enableWhen!
            var predicates = [NSPredicate]()
            for cond in conditions {
                let questionId = cond.question!.string
                let resultSelector = ORKResultSelector(stepIdentifier: questionId, resultIdentifier: questionId)
                if let bool = cond.answerBoolean {
                    let predicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: bool.bool)
                    let skipIfNot = NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
                    predicates.append(skipIfNot)
                }
                else if let coding = cond.answerCoding {
                    let value = coding.system!.absoluteString + kDelimiter + coding.code!.string
                    let predicate = ORKResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: value as NSCoding & NSCopying & NSObjectProtocol)
                    let skipIfNot = NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
                    predicates.append(skipIfNot)
                }
            }
            
            if !predicates.isEmpty {
                let compoundPredicate = NSCompoundPredicate.init(type: .or, subpredicates: predicates)
                let rule = ORKPredicateSkipStepNavigationRule(resultPredicate: compoundPredicate)
                nrules.append((rule, citem.linkId!.string))
            }
        }
        
        group.notify(queue: .main) {
            callback(nsteps.isEmpty ? nil : nsteps, nrules, nil)
        }
    }
    
    
    /*
    public func rule() -> ORKStepNavigationRule? {
        
        guard let conditions = enableWhen else {
            return nil
        }
        
        let condition = conditions.first
        let resultSelector = ORKResultSelector(resultIdentifier: condition!.question!.string)
        let predicate = ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: true)
        let rule = ORKPredicateStepNavigationRule(resultPredicatesAndDestinationStepIdentifiers: [(predicate, rk_Identifier())])
        return rule
    }*/
    
    
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
            callback(nil, SMError.instrumentQuestionnaireTypeMissing(linkId: linkId!.string))
            return
        }
        
        switch type {
        case .group:
            callback(nil, nil)
        case .display:   callback(nil, nil)
        case .boolean:
            callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
        case .date:
            callback(ORKAnswerFormat.dateAnswerFormat(), nil)
        case .dateTime:  callback(ORKAnswerFormat.dateTime(), nil)
        case .time:      callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
        case .string:    callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .url:       callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .integer:
            callback(ORKAnswerFormat.integerAnswerFormat(withUnit: nil), nil)
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
            } else if let answerSet = option {
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                let choices = answerSet.compactMap ({ $0.rk_choiceAnswerFormat(style: style) })
                let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
                callback(answerFormat, nil)
            }
            else {
                callback (nil, nil)
            }
        default:
            callback(nil, SMError.instrumentCannotHandleQuestionnaireType(linkId: linkId!.string))
            
        }
    }
    
    
}

let kDefaultSystem      = "CHOICESYSTEM"
let kDefaultAnserCode   = "ANSWERCODE"
let kDelimiter          = "|"


extension QuestionnaireItemOption {
    
    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKTextChoice? {
        
        if let vcoding = valueCoding {
            let system = vcoding.system?.absoluteString ?? kDefaultSystem
            let code = vcoding.code?.string ?? kDefaultAnserCode
            let value = system + kDelimiter + code
            let answerChoice = ORKTextChoice(text: vcoding.display?.string ?? code, value: value as NSCoding & NSCopying & NSObjectProtocol) // ::: TODO exclusive?
            return answerChoice
        }
        
        if let str = valueString?.string {
            return ORKTextChoice(text: str, value: str as NSCoding & NSCopying & NSObjectProtocol) // ::: TODO exclusive?
        }
        
        return nil
    }
}

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
