
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
            callback(nil, nil, SMError.instrumentQuestionnaireMissingItems(linkId: "root"))
            return
        }
        
        var nsteps = [ORKStep]()
        var nrules = [RuleTupple]()
        var errors = [Error]()
        let group = DispatchGroup()
        for item in items {
            group.enter()
            item.sm_generateSteps(callback: { (steps, rules, error) in
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
        
        assignVariables(to: nsteps as! [QuestionnaireItemStepProtocol])
    
        group.notify(queue: .main) {
            
            if nsteps.hasDuplicates() {
                errors.append(SMError.instrumentHasDuplicateLinkIds)
                nsteps.removeAll()
            }
            
            callback(nsteps.isEmpty ? nil : nsteps, nrules, errors.first)
        }
        
    }
    
    
    public func allItemsRecursively() -> [QuestionnaireItem] {
        let items = self.item ?? [QuestionnaireItem]()
        return items + items.flatMap { $0.allItemsRecursively() }
    }
    
    
    public func assignVariables(to steps: [QuestionnaireItemStepProtocol]) {
        
        guard let vextensions = self.extensions(forURI: kSD_Variable) else {
            print("no variable extensions")
            return
        }
        
        let expressions = vextensions.compactMap{ $0.valueExpression }
        
        for expression in expressions {
            let variable = expression.name!.string
            let nodes    = FHIRPathParser(expression.expression!.string, .keypath).nodes
            
            let itemNodes = nodes.filter ({ $0.keyPath == "item" && $0.cmd != nil }).compactMap ({ $0.cmd }).flatMap({$0})
            
            for node in itemNodes {
                if node.command == .where_fhir && node.key == "linkId" {
                    if var step = steps.filter({ $0.stepIdentifier == node._value }).first {
                        step.variable = variable
                    }
                }
            }
        }
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
        var errors = [Error]()
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
                    let step = QuestionnaireItemInstructionStep(identifier: self.rk_Identifier())
                    step.detailText = self.rk_InstructionText()
                    step.title = self.rk_text()
                    steps.append(step)
                    break
                    
                case .choice, .openChoice, .boolean, .date, .dateTime, .time, .string, .integer, .decimal:
                    do {
                        if let step = try QuestionnaireItemStep(self) {
                            step.answerFormat = answerFormat
                            steps.append(step)
                        }
                    }
                    catch {
                        errors.append(error)
                    }
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
                        let formSp = QuestionnaireFormStep.init(identifier: self.rk_Identifier(), title: self.text?.string, text: self.id?.string)
                        formSp.formItems = formItems
                        formSp.footnote = self.sm_questionItem_instructions()
                        steps.append(formSp)
                    } else {
                        
                        //TODO add error:
                        errors.append(SMError.instrumentQuestionnaireMissingItems(linkId: self.linkId!.string))
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
        
        callback(steps.isEmpty ? nil : steps, nrules, nil)
    }
    
    public func rk_text() -> String? {
        return text?.localized
    }
    
    public func rk_InstructionText() -> String? {
        return extensions(forURI: kSD_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    public func rk_HelpText() -> String? {
        return extensions(forURI: kSD_QuestionnaireHelp)?.first?.valueString?.localized
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
        case .group:        callback(nil, nil)
        case .display:      callback(nil, nil)
        case .boolean:      callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
        case .date:         callback(ORKAnswerFormat.dateAnswerFormat(), nil)
        case .dateTime:     callback(ORKAnswerFormat.dateTime(), nil)
        case .time:         callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
        case .string:       callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .url:          callback(ORKAnswerFormat.textAnswerFormat(), nil)
        case .integer:      callback(ORKAnswerFormat.integerAnswerFormat(withUnit: nil), nil)
        case .decimal:      callback(ORKAnswerFormat.decimalAnswerFormat(withUnit: nil), nil)
        case .choice:
            if let answerValueSet = answerValueSet {
                
                if answerValueSet.absoluteString == kVS_YesNoDontknow {
                    //TODO Canonical Resolve :::
                }
                else {
                    let style: ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                    let semaphore = DispatchSemaphore(value: 0)
                    answerValueSet.resolve(ValueSet.self) { (resolvedVS) in
                        if let answerVS = resolvedVS, let af = answerVS.rk_choiceAnswerFormat(style: style) {
                            callback(af, nil)
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


public func sm_AnswerChoice(system: FHIRURL?, code: FHIRString, display: FHIRString?, displayText: String? = nil, detailText: String? = nil) -> ORKTextChoice? {
    
    let displayStr = displayText ?? display?.string ?? code.string
    let answer = system?.absoluteString ?? kDefaultSystem + kDelimiter + code.string
    let answerChoice = ORKTextChoice(text: displayStr, detailText: detailText, value: answer as NSCoding & NSCopying & NSObjectProtocol, exclusive: true)
    return answerChoice
}



extension Coding {
    
    public func sm_textAnswerChoice() -> ORKTextChoice? {
        
        return sm_AnswerChoice(system: system, code: code!, display: display)
        
    }
}
extension QuestionnaireItemAnswerOption {
    
    public func rk_choiceAnswerFormat(style: ORKChoiceAnswerStyle = .singleChoice) -> ORKTextChoice? {
        
        if let vcoding = valueCoding {
            return vcoding.sm_textAnswerChoice()
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
                if let textChoice = sm_AnswerChoice(system: option.system, code: option.code!, display: option.display, displayText: option.display_localized) {
                    choices.append(textChoice)
                }
            }
        }
        
        else if let includes = compose?.include {
            for include in includes {
                include.concept?.forEach({ (concept) in
                    if let answerChoice = sm_AnswerChoice(system: include.system, code: concept.code!, display: concept.display, displayText: concept.display_localized) {
                        choices.append(answerChoice)
                    }
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
    
    public func populateAnswer(into response: inout QuestionnaireResponse, for step: ORKStep) {
        
    }
}


extension SMART.Element {
    
    
    public func sm_questionItem_instructions() -> String? {
        return extensions(forURI: kSD_QuestionnaireInstruction)?.first?.valueString?.localized
    }
    
    public func sm_questionItem_Help() -> String? {
        return extensions(forURI: kSD_QuestionnaireHelp)?.first?.valueString?.localized
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
            let value = coding.system!.absoluteString + kDelimiter + coding.code!.string
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
        default:
            break
        }
        
        return predicates.isEmpty ? nil : predicates
    }
    
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

