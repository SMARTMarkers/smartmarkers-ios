//
//  QuestionStep.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 7/5/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

public protocol PROStepProtocol : class {
    
    var identifier: String  { get}
    
    var order: UInt { get set }
    
    var title : String? { get set }
    
    var linkIds : [String]? {  get set }
    
    var _parent : PROStepProtocol? { get set }
    
    var condition: StepCondition? { get set }
    
    init(_identifier: String, parentItem: PROStepProtocol?, title: String?, text: String? , condition: StepCondition?)
}


extension PROStepProtocol where Self : ORKStep {
    
    public var identifier : String {
        return self.identifier
    }
    public var title: String? {
        return self.title
    }
    public init(_identifier: String, parentItem: PROStepProtocol?, title: String? = nil, text: String? = nil, condition: StepCondition? = nil) {
        self.init(identifier: _identifier)
        self._parent = parentItem
        self.order = 0
        self.title = title
        self.text = text
        self.condition = condition
    }
}




public class PROQuestionStep: ORKQuestionStep, PROStepProtocol {
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
    public var _parent: PROStepProtocol?
    
    public var condition: StepCondition?
    
}


public class PROInstructionStep: ORKInstructionStep, PROStepProtocol {
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
    public var _parent: PROStepProtocol?
    
    public var condition: StepCondition?
    
}







public struct StepCondition {
    
    let questionId: String
    let hasAnswer: String
    let isAnswer: String
    
    
}


