
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
        
        var itemSteps = [ORKStep]()
        var navigationRules = [RuleTupple]()
        var all_errors = [Error]()

        let sema = DispatchSemaphore(value: 1)
        for item in items {
            item.sm_generateSteps(callback: { [self] (steps, rules, errors) in
                if let errors = errors {
                    all_errors.append(contentsOf: errors)
                }
                
                if let steps = steps {
                    steps.forEach({ if $0.title == nil { $0.title = sm_title }})
                    itemSteps.append(contentsOf: steps)
                }
                
                if let rules = rules {
                    navigationRules.append(contentsOf: rules)
                }
                
                sema.signal()
            })
         
            sema.wait()
        }
                    
            if itemSteps.sm_hasDuplicates() {
                all_errors.append(SMError.instrumentHasDuplicateLinkIds)
                itemSteps.removeAll()
            }
            
            
            if all_errors.count == 0 {
                callback(itemSteps.isEmpty ? nil : itemSteps, navigationRules, nil)

            }
            else {
                callback(nil, nil, all_errors.isEmpty ? nil : all_errors)

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
//                smLog(error)
            }
            else {
                switch self.type! {
                case .display:
                    do {
                        if let step = try ItemInstructionStep(self) {
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
//                        let newgroup = DispatchGroup()
                        let sem2 = DispatchSemaphore(value: 0)
                        for subitem in subItems {
//                            newgroup.enter()
                            subitem.sm_generateSteps(callback: { (steps, rules, errs ) in
                                if let errs = errs {
                                    all_errors.append(contentsOf: errs)
                                }
                                if let steps = steps {
                                    subSteps.append(contentsOf: steps)
                                }
//                                newgroup.leave()
                                sem2.signal()
                            })
//                            newgroup.wait()
                            sem2.wait()
                        }
                        if subSteps.isEmpty {
                            let err_msg = "Could Not create Questionnaire `form` item with linkId: \(self.linkId?.string ?? ""); Unable to create `ORKSteps`"
                            all_errors.append(SMError.undefined(description: err_msg))
                            break
                        }
                        let formItems = subSteps.flatMap  { $0.sm_toFormItem()! }
                        do {
                            if let formStep = try QuestionnaireFormStep(self) {
                                // add a section title
                                let formitemSectionTitle = ORKFormItem(sectionTitle: self.text?.string)
                                formStep.formItems = [formitemSectionTitle] + formItems
                                steps.append(formStep)
                            }
                        }
                        catch {
                            all_errors.append(error)
                        }
                    } else {
                        
                        all_errors.append(SMError.instrumentQuestionnaireMissingItems(linkId: self.linkId!.string))
                    }
                    break
                default:
                    break
                }
            }
        })
        
        if all_errors.count == 0 {
            conditionalItems.forEach { (citem) in
                if let rule = citem.sm_enableWhenPredicate() {
                    nrules.append((rule, citem.linkId!.string))
                }
            }
            callback(steps.isEmpty ? nil : steps, nrules, all_errors.isEmpty ? nil : all_errors)
        }
        else {
            callback(nil, nil, all_errors)
        }

    }

    public func rk_Identifier() -> String {
        return linkId?.string ?? UUID().uuidString
    }
    
    public func rk_answerFormat(callback: @escaping (_ answer: ORKAnswerFormat?, _ error :Error?) -> Void) {
        
        guard let type = type else {
            callback(nil, SMError.instrumentQuestionnaireTypeMissing(linkId: linkId!.string))
            return
        }
        
        let itemControl = sm_questionItemControl()
        
        switch type {
        case .group:
            callback(nil, nil)
            
        case .display:
            callback(nil, nil)
            
        case .boolean:
            callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
            
        case .date:
            let answerFormat = ORKAnswerFormat.dateAnswerFormat(
                withDefaultDate: initial?.first?.valueDate?.nsDate,
                minimumDate: extensions(forURI: kSD_QuestionnaireMinValue)?.first?.valueDate?.nsDate,
                maximumDate: extensions(forURI: kSD_QuestionnaireMaxValue)?.first?.valueDate?.nsDate,
                calendar: Calendar.current
            )
            callback(answerFormat, nil)
            
        case .dateTime:
            callback(ORKAnswerFormat.dateTime(), nil)
            
        case .time:
            callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
            
        case .text:
            let answerFormat = ORKTextAnswerFormat()
            answerFormat.multipleLines = true
            callback(answerFormat, nil)
            
        case .string:
            if let pattern = self.sm_questionItem_RegexPattern() {
                let expression = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let format = ORKTextAnswerFormat(validationRegularExpression: expression, invalidMessage: "Invalid Entry")
                callback(format, nil)
            }
            else {
                callback(ORKAnswerFormat.textAnswerFormat(), nil)
            }
            
        case .url:
            callback(ORKTextAnswerFormat(), nil)
            
        case .integer:
            let min = extensions(forURI: kSD_QuestionnaireMinValue)?.first?.valueInteger?.int
            let max = extensions(forURI: kSD_QuestionnaireMaxValue)?.first?.valueInteger?.int
            let minNumber : NSNumber? = (min != nil) ? NSNumber(value: min!) : nil
            let maxNumber : NSNumber? = (max != nil) ? NSNumber(value: max!) : nil
            let answerFormat = IfWeightItem() ?? IfHeightItem() ?? ORKNumericAnswerFormat(
                style: .integer, unit: itemUnit(), minimum: minNumber, maximum:maxNumber, maximumFractionDigits: nil)
            callback(answerFormat, nil)
            
        case .decimal:
            let min = extensions(forURI: kSD_QuestionnaireMinValue)?.first?.valueDecimal?.decimal
            let max = extensions(forURI: kSD_QuestionnaireMaxValue)?.first?.valueDecimal?.decimal
            let minNumber : NSNumber? = (min != nil) ? NSDecimalNumber(decimal: min!) : nil
            let maxNumber : NSNumber? = (max != nil) ? NSDecimalNumber(decimal: max!) : nil
            let answerFormat = IfWeightItem() ?? IfHeightItem() ?? ORKNumericAnswerFormat(
                style: .decimal, unit: itemUnit(), minimum: minNumber, maximum:maxNumber, maximumFractionDigits: nil)
            callback(answerFormat, nil)
            
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
                
                
                let answerFormat: ORKAnswerFormat
                let style : ORKChoiceAnswerStyle = (repeats?.bool ?? false) ? .multipleChoice : .singleChoice
                let choices = answerSet.compactMap ({ $0.rk_choiceAnswerFormat(style: style) })
                
                // itemControl == slider
                if itemControl == "slider" {
                    // TextScale slider in ResearchKit only works with a max of 8 choices
                    if choices.count > 8 {
                        answerFormat = ORKAnswerFormat.valuePickerAnswerFormat(with: choices)
                    }
                    else {
                        let slider = ORKTextScaleAnswerFormat(textChoices: choices, defaultIndex: -1, vertical: false)
                        slider.shouldHideRanges = true
                        answerFormat = slider
                    }
                }
                else {
                    answerFormat = ORKAnswerFormat.choiceAnswerFormat(with: style, textChoices: choices)
                }
                
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
        
        // TODO: Add value reference
//        if let valueReference {
//
//            return ORKTextChoice(text: valueReference.display?.string ?? valueReference.reference!.string,
//                                 primaryTextAttributedString: nil,
//                                 detailText: valueReference.reference!.string,
//                                 detailTextAttributedString: nil,
//                                 value: valueReference.reference!.string as NSCoding & NSCopying & NSObjectProtocol,
//                                 exclusive: (style == .singleChoice) ? true : false)
//        }
        
        if let valueCoding = valueCoding {
            return valueCoding.sm_textAnswerChoice(style: style, answerOption: self)
        }
        
        if let string = valueString?.string {
            return ORKTextChoice(
                text: string,
                detailText: nil,
                value: string as NSCoding & NSCopying & NSObjectProtocol,
                exclusive: (style == .singleChoice) ? true : false
            )
        }
        
        if let integer = valueInteger?.int {
            return ORKTextChoice(
                text: String(integer),
                detailText: nil,
                value: NSNumber(value: Double(integer)) as NSCoding & NSCopying & NSObjectProtocol,
                exclusive: (style == .singleChoice) ? true : false
            )
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









public extension ResearchKit.ORKStep {
    
    func sm_toFormItem(_ prefixIdentifier: String? = nil) -> [ORKFormItem]? {
        if let slf = self as? ORKQuestionStep {
            let item = ORKFormItem(identifier: (prefixIdentifier ?? "") + slf.identifier,
                                      text: slf.question,
                                      detailText: slf.detailText,
                                      learnMoreItem: nil,
                                      showsProgress: true,
                                      answerFormat: slf.answerFormat,
                                      tagText: nil,
                                      optional: slf.isOptional)
            return [item]
        }
        else {
            let formItem = ORKFormItem(identifier: self.identifier , text: self.text, answerFormat: nil)
            return [formItem]
        }
    }
}


extension QuestionnaireItemEnableWhen {
    
    func sm_resultPredicate(itemType: QuestionnaireItemType?, _ existsOperator: Bool? = nil) -> NSPredicate? {
        
        let resultSelector = ORKResultSelector(stepIdentifier: question!.string, resultIdentifier: question!.string)
                
        if let string = answerString?.string {
            return ORKResultPredicate.predicateForChoiceQuestionResult(with: resultSelector, expectedAnswerValue: string as NSCoding & NSCopying & NSObjectProtocol)
        }
        
        if let integer = answerInteger?.int {
            switch self.operator_fhir {
            case .gte, .lt, .lte, .gt, .eq, .ne:
                let value = NSNumber(value: Double(integer))
                let predicateString = "SUBQUERY(SELF, $x, $x.identifier == $ORK_TASK_IDENTIFIER AND SUBQUERY($x.results, $y, $y.identifier == %@ AND $y.isPreviousResult == 0 AND SUBQUERY($y.results, $z, $z.identifier == %@ AND $z.answer \(operator_fhir!.rawValue) %@).@count > 0).@count > 0).@count > 0"
                let args: [CVarArg] = [question!.string, question!.string, value]
                return NSPredicate(format: predicateString, arguments: getVaList(args))
            default:
                return nil
            }
        }
                
        if let bool = answerBoolean {
            if let existsOperator = existsOperator, existsOperator == true {
                let is_nil = ORKResultPredicate.predicateForNilQuestionResult(with: resultSelector)
                return is_nil
            }
            else {
                return ORKResultPredicate.predicateForBooleanQuestionResult(with: resultSelector, expectedAnswer: bool.bool)
            }
        }
        
        if let coding = answerCoding {
            /*
            Reverse engineered the RK Predicate to work with `valueCoding`
            Problem: Coding.display is optional. To represent valueCoding with Display,
            we encode the answer with or without coding.display.
            To work with ResearchKit, we write a custom predicate where the framework checks whether coding.system and coding.code
            match the given answer. For this `BEGINWITH` is sufficient as we check the system and code and optionally the display
            As usual, we match the questionnaire linkId.
            */
            let value = (coding.system?.absoluteString ?? kDefaultSystem) + kDelimiter + coding.code!.string + kDelimiter
            let valueWithDisplay = value + (coding.display?.string ?? "")
            let predicateString = "SUBQUERY(SELF, $x, $x.identifier == $ORK_TASK_IDENTIFIER AND SUBQUERY($x.results, $y, $y.identifier == %@ AND $y.isPreviousResult == NO AND SUBQUERY($y.results, $z, $z.identifier == %@ AND SUBQUERY($z.answer, $w, ($w == %@) || ($w BEGINSWITH %@)).@count > 0).@count > 0).@count > 0).@count > 0"
            let args: [CVarArg] = [question!.string, question!.string, value, valueWithDisplay]
            return NSPredicate(format: predicateString, arguments: getVaList(args))
        }
        return nil
    }
    
    func sm_enableWhenPredicate() -> [NSPredicate]? {
        

        // TODO:
        // Error handling and throws
        
        var predicates = [NSPredicate]()
        let enableOperator = operator_fhir
        switch enableOperator! {
        case .eq, .gte, .lte:
            guard let resultPredicate = sm_resultPredicate(itemType: nil) else {
                return nil
            }
            let skipIfNot = NSCompoundPredicate(notPredicateWithSubpredicate: resultPredicate)
                predicates.append(skipIfNot)
            break
        case .ne:
            guard let resultPredicate = sm_resultPredicate(itemType: nil) else {
                return nil
            }
            let skipIf = NSCompoundPredicate(andPredicateWithSubpredicates: [resultPredicate])
            predicates.append(skipIf)
            break
        case .exists:
            guard let is_nil = sm_resultPredicate(itemType: nil, true),
                  let shouldExist = answerBoolean?.bool else {
                return nil
            }
            if shouldExist {
                let shouldNotSkipIfExist = is_nil
                predicates.append(shouldNotSkipIfExist)
            }
            else {
                let shouldSkipIfExist = NSCompoundPredicate(notPredicateWithSubpredicate: is_nil)
                predicates.append(shouldSkipIfExist)
            }
            break
            
        default:
            break
        }
        
        return predicates.isEmpty ? nil : predicates
    }
    
}



