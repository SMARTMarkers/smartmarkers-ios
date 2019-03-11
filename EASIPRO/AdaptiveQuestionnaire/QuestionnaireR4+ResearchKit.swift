//
//  QuestionnaireR4+ResearchKit.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


extension QuestionnaireR4 {
    
    public func sm_generateResearchKitSteps(callback: @escaping (StepsCallback)) {
        
        guard let items = self.item else {
            callback(nil, nil, SMError.instrumentQuestionnaireMissingItems)
            return
        }
        
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var errors = [Error]()
        let group = DispatchGroup()
        for item in items {
            group.enter()
            item.sm_generateResearchKitSteps(callback: { (steps, rules, error) in
                if let error = error {
                    errors.append(error)
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
            
            if nsteps.hasDuplicates() {
                errors.append(SMError.instrumentHasDuplicateLinkIds)
                nsteps.removeAll()
            }
            
            callback(nsteps.isEmpty ? nil : nsteps, nrules, errors.first)
        }
        
    }
    
}

extension QuestionnaireItemR4 {
    
    public func sm_generateResearchKitSteps(callback: @escaping (StepsCallback)) {
    
        
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var conditionalItems = [QuestionnaireItemR4]()
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
                    let step = ORKInstructionStep(identifier: self.stepIdentifier())
                    step.detailText = self.sm_questionItem_instructions()
                    step.text = self.text?.string
                    nsteps.append(step)
                    break
            case .choice, .openChoice, .boolean, .date, .dateTime, .time, .string, .integer:
                    let step = ORKQuestionStep(identifier: self.stepIdentifier(), title: self.text?.string, question: self.text?.string, answer: answerFormat)
                    nsteps.append(step)
                    break
                    
                case .group:
                    if let subItems = self.item {

                        var subSteps = [ORKStep]()
                        let newgroup = DispatchGroup()
                        for subitem in subItems {
                            newgroup.enter()
                            subitem.sm_generateResearchKitSteps(callback: { (steps, rules, err ) in
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
                        let formSp = ORKFormStep.init(identifier: self.stepIdentifier(), title: self.text?.string, text: self.id!.string)
                        formSp.formItems = formItems

                        formSp.footnote = self.sm_questionItem_instructions()
                        nsteps.append(formSp)
                        
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
    
    func stepIdentifier() -> String {
//        return UUID().uuidString
        return linkId!.string
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
            } else if let answerSet = answerOption {
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                let choices = answerSet.compactMap ({ $0.rk_choiceAnswerFormat(style: style) })
                let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
                callback(answerFormat, nil)
            }
            else {
                callback (nil, SMError.instrumentQuestionnaireItemMissingOptions(linkId: linkId!.string))
            }
        default:
            callback(nil, SMError.instrumentCannotHandleQuestionnaireType(linkId: linkId!.string))
            
        }
    }
    
    
}



extension SMART.Element {
    
    
    public func sm_questionItem_instructions() -> String? {
        return extensions(forURI: kStructureDefinition_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    public func sm_questionItem_Help() -> String? {
        return extensions(forURI: kStructureDefinition_QuestionnaireHelp)?.first?.valueString?.localized
    }
    
}


extension ResearchKit.ORKStep {
    
    func sm_toFormItem() -> [ORKFormItem]? {
        

        
        if let slf = self as? ORKQuestionStep {
            
            let formItem = ORKFormItem(identifier: slf.identifier , text: slf.question, answerFormat: slf.answerFormat)
            
            return [formItem]
        }
        else {
              let formItem = ORKFormItem(identifier: self.identifier , text: self.text, answerFormat: nil)
            return [formItem]
//            return [ORKFormItem(sectionTitle: self.text)]
            
        }
    }
}
