
//  Questionnaire+Extensions.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 7/3/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

public typealias RuleTupple = (ORKPredicateSkipStepNavigationRule, String)
public typealias StepsCallback = (_ steps: [ORKStep]?, _ rules: [RuleTupple]?, _ error: [Error]?) -> Void



extension Questionnaire  {

    public func sm_genereteSteps(callback: @escaping StepsCallback) {
        
        guard let items = self.item else {
            callback(nil, nil, [SMError.instrumentQuestionnaireMissingItems(linkId: "root")])
            return
        }
        
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var all_errors = [Error]()
        let group = DispatchGroup()
        for item in items {
            group.enter()
            item.sm_generateSteps(callback: { (steps, rules, errors) in
                if let errors = errors {
                    all_errors.append(contentsOf: errors)
                }
                
                if let steps = steps {
                    nsteps.append(contentsOf: steps)
                }
                
                if let rules = rules {
                    nrules.append(contentsOf: rules)
                }
                
                group.leave()
            })
        }

        group.notify(queue: .main) {
            
            if nsteps.sm_hasDuplicates() {
                all_errors.append(SMError.instrumentHasDuplicateLinkIds)
                nsteps.removeAll()
            }
            
            callback(nsteps.isEmpty ? nil : nsteps, nrules, all_errors.isEmpty ? nil : all_errors)
        }
        
    }
    
    
    public func allItemsRecursively() -> [QuestionnaireItem] {
        let items = self.item ?? [QuestionnaireItem]()
        return items + items.flatMap { $0.allItemsRecursively() }
    }
}

extension QuestionnaireItem {
    
    public func allItemsRecursively() -> [QuestionnaireItem] {
        let items = self.item ?? [QuestionnaireItem]()
        return items + items.flatMap { $0.allItemsRecursively() }
    }
    
    public func sm_generateSteps(callback: @escaping StepsCallback) {
        var steps = [ORKStep]()
        var nrules = [RuleTupple]()
        var conditionalItems = [QuestionnaireItem]()
        var all_errors = [Error]()
        if self.enableWhen != nil {
                conditionalItems.append(self)
        }
        self.rk_answerFormat(callback: { (answerFormat, zerror) in
            if let error = zerror {
                print(error)
            }
            else {
                switch self.type! {
                case .display:
                    do {
                        if let step = try QuestionnaireItemInstructionStep(self) {
                            step.detailText = self.sm_questionItem_instructions()
                            step.title = self.text?.localized
                            steps.append(step)
                        }
                    }
                    catch {
                        all_errors.append(error)
                    }
                    break
                    
                case .choice, .openChoice, .boolean, .date, .dateTime, .time, .string, .integer, .decimal, .text, .url:
                    do {
                        if let step = try QuestionnaireItemStep(self) {
                            step.answerFormat = answerFormat
                            steps.append(step)
                        }
                    }
                    catch {
                        all_errors.append(error)
                    }
                    break
                    
                case .group:
                    if let subItems = self.item {
                        var subSteps = [ORKStep]()
                        let newgroup = DispatchGroup()
                        for subitem in subItems {
                            newgroup.enter()
                            subitem.sm_generateSteps(callback: { (steps, rules, errs ) in
                                if let errs = errs {
                                    all_errors.append(contentsOf: errs)
                                }
                                if let steps = steps {
                                    subSteps.append(contentsOf: steps)
                                }
                                newgroup.leave()
                            })
                            newgroup.wait()
                        }
                        if subSteps.isEmpty {
                            let err_msg = "Could Not create Questionnaire `form` item with linkId: \(self.linkId?.string ?? ""); Unable to create `ORKSteps`"
                            all_errors.append(SMError.undefined(description: err_msg))
                            break
                        }
                        let formItems = subSteps.flatMap  { $0.sm_toFormItem()! }
                        let formSp = QuestionnaireFormStep.init(identifier: self.rk_Identifier(), title: self.text?.string, text: self.id?.string)
                        formSp.formItems = formItems
                        formSp.footnote = self.sm_questionItem_instructions()
                        steps.append(formSp)
                    } else {
                        
                        all_errors.append(SMError.instrumentQuestionnaireMissingItems(linkId: self.linkId!.string))
                    }
                    break
                default:
                    break
                }
            }
        })
        
        conditionalItems.forEach { (citem) in
            if let rule = citem.sm_enableWhenPredicate() {
                nrules.append((rule, citem.linkId!.string))
            }
        }

        callback(steps.isEmpty ? nil : steps, nrules, all_errors.isEmpty ? nil : all_errors)
    }

    public func rk_Identifier() -> String {
        return linkId?.string ?? UUID().uuidString
    }
    
    public func rk_answerFormat(callback: @escaping (_ answer: ORKAnswerFormat?, _ error :Error?) -> Void) {
        
        guard let type = type else {
            callback(nil, SMError.instrumentQuestionnaireTypeMissing(linkId: linkId!.string))
            return
        }
        
        switch type {
        case .group:
            callback(nil, nil)
            
        case .display:
            callback(nil, nil)
            
        case .boolean:
            callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
            
        case .date:
            callback(ORKAnswerFormat.dateAnswerFormat(), nil)
            
        case .dateTime:
            callback(ORKAnswerFormat.dateTime(), nil)
            
        case .time:
            callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
            
        case .string, .text:
            callback(ORKAnswerFormat.textAnswerFormat(), nil)
            
        case .url:
            callback(ORKAnswerFormat.textAnswerFormat(), nil)
            
        case .integer:
            callback(ORKAnswerFormat.integerAnswerFormat(withUnit: itemUnit()), nil)
            
        case .decimal:
            callback(IfWeightItem() ?? IfHeightItem() ?? ORKAnswerFormat.decimalAnswerFormat(withUnit: itemUnit()), nil)
            
        case .choice, .openChoice:

            if let answerValueSet = answerValueSet {
                if answerValueSet.absoluteString == kVS_YesNoDontknow {
                    callback(ORKAnswerFormat.sm_hl7YesNoDontKnow(), nil)
                }
                else {
                    let style: ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                    let semaphore = DispatchSemaphore(value: 0)
                    answerValueSet.resolve(ValueSet.self) { (resolvedVS) in
                        if let aValueSet = resolvedVS, let answerFormat = aValueSet.rk_choiceAnswerFormat(style: style) {
                            callback(answerFormat, nil)
                        }
                        else {
                            callback(nil, SMError.instrumentCannotHandleQuestionnaireType(linkId: self.linkId!.string))
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
                
            } else if let answerSet = answerOption {
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                let choices = answerSet.compactMap ({ $0.rk_choiceAnswerFormat(style: style) })
                let answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
                callback(answerFormat, nil)
            }
            else {
                callback (nil, SMError.instrumentCannotHandleQuestionnaireType(linkId: linkId!.string))
            }
        default:
            callback(nil, SMError.instrumentCannotHandleQuestionnaireType(linkId: linkId!.string))
        }
    }
    
    
    func sm_enableWhenPredicate() -> ORKPredicateSkipStepNavigationRule? {
        
        guard let resultPredicates = enableWhen?.flatMap({ $0.sm_enableWhenPredicate()! }) else {
            return nil
        }
        
        let logicalType : NSCompoundPredicate.LogicalType = (resultPredicates.count > 1) ? ((enableBehavior == .all) ? .or : .and) : .and
        let compoundPredicate = NSCompoundPredicate(type: logicalType, subpredicates: resultPredicates)
        let rule = ORKPredicateSkipStepNavigationRule(resultPredicate: compoundPredicate)
        
        return rule
    }
    
    
}



let kDefaultSystem      = "CHOICESYSTEM"
let kDefaultAnserCode   = "ANSWERCODE"
let kDelimiter          = "≠"



extension QuestionnaireItemAnswerOption {
    
    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKTextChoice? {
        
        if let valueCoding = valueCoding {
            return valueCoding.sm_textAnswerChoice()
        }
        
        if let string = valueString?.string {
            return ORKTextChoice(text: string, value: string as NSCoding & NSCopying & NSObjectProtocol) // ::: TODO exclusive?
        }
        
        return nil
    }
}

extension ORKAnswerFormat {
    
    // kVS_YesNoDontknow = "http://hl7.org/fhir/ValueSet/yesnodontknow"
    class func sm_hl7YesNoDontKnow() -> ORKAnswerFormat {
        let textChoices = [
            ORKTextChoice.sm_AnswerChoice(system: "http://terminology.hl7.org/CodeSystem/v2-0136", code: "Y", display: "Yes")!,
            ORKTextChoice.sm_AnswerChoice(system: "http://terminology.hl7.org/CodeSystem/v2-0136", code: "N", display: "No")!,
            ORKTextChoice.sm_AnswerChoice(system: "http://terminology.hl7.org/CodeSystem/data-absent-reason", code: "asked-unknown", display: "Don't Know")!
        ]
        
        return ORKAnswerFormat.choiceAnswerFormat(with: .singleChoice, textChoices: textChoices)
    }
}





extension ORKChoiceQuestionResult {
    
    public func populateAnswer(into response: inout QuestionnaireResponse, for step: ORKStep) {
        
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
        }
    }
}


extension QuestionnaireItemEnableWhen {
    
    func sm_resultPredicate() -> NSPredicate? {
        
        let resultSelector = ORKResultSelector(stepIdentifier: question!.string, resultIdentifier: question!.string)
        if let bool = answerBoolean {
            return ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: bool.bool)
        }
        else if let coding = answerCoding {
            // TODO
            let value = (coding.system?.absoluteString ?? kDefaultSystem) + kDelimiter + coding.code!.string
            return ORKResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: value as NSCoding & NSCopying & NSObjectProtocol)
        }
        return nil
    }
    
    func sm_enableWhenPredicate() -> [NSPredicate]? {
        
        guard let resultPredicate = sm_resultPredicate() else {
            return nil
        }
        var predicates = [NSPredicate]()
        let enableOperator = operator_fhir
        switch enableOperator! {
        case .eq:
            let skipIfNot = NSCompoundPredicate(notPredicateWithSubpredicate: resultPredicate)
            predicates.append(skipIfNot)
            break
        case .ne:
            let skipIf = NSCompoundPredicate(andPredicateWithSubpredicates: [resultPredicate])
            predicates.append(skipIf)
            break
        default:
            break
        }
        
        return predicates.isEmpty ? nil : predicates
    }
    
}


