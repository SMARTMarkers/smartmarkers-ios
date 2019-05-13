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


extension Questionnaire  {

    public func sm_genereteSteps(callback: @escaping StepsCallback) {
        
        guard let items = self.item else {
            callback(nil, nil, SMError.instrumentQuestionnaireMissingItems)
            return
        }
        
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "stepsQueue")
        let semaphore = DispatchSemaphore(value: 1)
        queue.async(group: group) {
            for item in items {
                group.enter()
                item.sm_generateSteps(callback: { (steps, rules, error) in
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
                    semaphore.signal()
                    group.leave()
                })
                semaphore.wait()
            }
        }
        
        
        group.notify(queue: queue) {
            DispatchQueue.main.async {
                callback(nsteps.isEmpty ? nil:nsteps, nrules, nil)
            }
        }
        
    }
}

extension QuestionnaireItem {
    
    
    public func sm_generateSteps(callback: @escaping StepsCallback) {
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var conditionalItems = [QuestionnaireItem]()
        if self.enableWhen != nil {
                conditionalItems.append(self)
        }
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
                    let step = ORKQuestionStep(identifier: self.rk_Identifier(), title: nil, question: self.rk_text(), answer: answerFormat)
                    nsteps.append(step)
                    break
                    
                case .group:
                    if let subItems = self.item {
                        var subSteps = [ORKStep]()
                        let newgroup = DispatchGroup()
                        for subitem in subItems {
                            newgroup.enter()
                            subitem.sm_generateSteps(callback: { (steps, rules, err ) in
                                if let error = err {
                                    print(error as Any)
                                }
                                else if let steps = steps {
                                    subSteps.append(contentsOf: steps)
                                }
                                newgroup.leave()
                            })
                            newgroup.wait()
                        }
                        
                        let formItems = subSteps.flatMap  { $0.sm_toFormItem()! }
                        let formSp = ORKFormStep.init(identifier: self.rk_Identifier(), title: self.text?.string, text: self.id!.string)
                        formSp.formItems = formItems
                        formSp.footnote = self.sm_questionItem_instructions()
                        nsteps.append(formSp)
                    }
                    break
                default:
                    break
                }
            }
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
        callback(nsteps.isEmpty ? nil : nsteps, nrules, nil)
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
            if let _ = answerValueSet {
                
                //TODO:
                /*
                let vsReference = Reference()
                
                let vs = ValueSet(
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                let dispatchSemaphore = DispatchSemaphore(value: 0)
                answerValueSet.resolve(ValueSet.self, callback: { (choices) in
                    if let choices = choices, let af = choices.rk_choiceAnswerFormat(style: style) {
                        callback(af, nil)
                    } else {
                        callback(nil, nil)
                    }
                    dispatchSemaphore.signal()
                })
                dispatchSemaphore.wait()
                */

                
            } else if let answerSet = answerOption {
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
let kDelimiter          = "≠"

extension QuestionnaireItemAnswerOption {
    
    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKTextChoice? {
        
        if let vcoding = valueCoding {
            
            let system = vcoding.system?.absoluteString ?? kDefaultSystem
            let code = vcoding.code?.string ?? kDefaultAnserCode
            var value = system + kDelimiter + code
            
            if let display = vcoding.display?.string {
                value += kDelimiter + display
            }
            
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
                var value = system + kDelimiter + code
                if let display = option.display?.string {
                    value += kDelimiter + display
                }
                let answerChoice = ORKTextChoice(text: option.display_localized ?? code, detailText: nil, value: value as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
                choices.append(answerChoice)
            }
        }
        
        else if let includes = compose?.include {
            for include in includes {
                let system = include.system?.absoluteString ?? kDefaultSystem
                include.concept?.forEach({ (concept) in
                    let code = concept.code?.string ?? kDefaultAnserCode
                    var value = system + kDelimiter + code
                    
                    if let display = concept.display?.string {
                        value += kDelimiter + display
                    }
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




extension ORKChoiceQuestionResult {
    
    public func populateAnswer(into response: inout QuestionnaireResponseR4, for step: ORKStep) {
        
    }
}
