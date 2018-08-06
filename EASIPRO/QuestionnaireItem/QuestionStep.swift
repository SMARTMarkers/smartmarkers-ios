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
    
    var order: UInt { get set }
    
    var title : String? { get set }
    
    var linkIds : [String]? {  get set }
    
    var _parent : PROStepProtocol? { get set }
    
    init(_identifier: String, parentItem: PROStepProtocol?)
    
}



extension PROStepProtocol where Self : ORKStep {
    
    public init(_identifier: String, parentItem: PROStepProtocol?) {
        self.init(identifier: _identifier)
        _parent = parentItem
        order = 0
    }
    
    public static func initialise(_ qItem: QuestionnaireItem,  callback: @escaping (_ step: Self?, _ error: Error?) -> Void) {
        
        let step = Self(identifier: qItem.rk_Identifier())
        step.title = qItem.text?.string
        
        if let slf = step as? PROQuestionStep {
            
            qItem.rk_answerFormat { (format, error) in
                if let format = format {
                    slf.answerFormat = format
                    callback(step, nil)
                }
                else {
                    callback(nil, nil)
                }
            }
        }
        
        if let slf = step as? PROInstructionStep {
            slf.detailText = "Detail"
            callback(step, nil)
        }
        
        if let slf = step as? PROFormStep {
            
        }
        

        
        
    }
    
    public init(_ questionnaireItem: QuestionnaireItem) {
        
        let identifier = questionnaireItem.rk_Identifier()
        self.init(_identifier: identifier, parentItem: nil)
        self.title = questionnaireItem.text?.string
        
        if let slf = self as? PROQuestionStep {
            questionnaireItem.rk_answerFormat { (format, error) in
                slf.answerFormat = format
                print(slf.answerFormat)
            }
            
        }
        
        if let slf = self as? PROInstructionStep {
            slf.detailText = "Detailed Instruction"
        }
        
        if let slf = self as? PROFormStep {
            
        }
    }

}







public class PROInstructionStep : ORKInstructionStep, PROStepProtocol {
   
    
    
    public weak var _parent: PROStepProtocol?
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
    
}

public class PROQuestionStep : ORKQuestionStep, PROStepProtocol {
    
    public weak var _parent: PROStepProtocol?
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
}
public class PROFormStep : ORKFormStep, PROStepProtocol {
    
    public weak var _parent: PROStepProtocol?
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
}

public class PROCompletionStep : ORKCompletionStep, PROStepProtocol {
    
    public weak var _parent: PROStepProtocol?
    
    public var order: UInt = 0
    
    public var linkIds: [String]?
    
}


