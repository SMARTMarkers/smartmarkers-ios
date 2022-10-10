//
//  QuestionnaireItemStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 5/23/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


public protocol QuestionnaireItemStepProtocol {
    
    var stepIdentifier: String { get }
    
    var type: String? { get set }
    
    var result: ORKResult? { get }
        
    init?(_ item: QuestionnaireItem) throws
}



public extension QuestionnaireItemStepProtocol where Self : ORKStep {
    
    init?(_ item: QuestionnaireItem) throws {
        
        guard let linkId = item.linkId?.string else {
            throw SMError.undefined(description: "Questionnaire.Item does not have required attribute = linkId")
        }
        self.init(identifier: linkId)
        self.type = item.type?.rawValue
        isOptional = (item.required?.bool != nil) ? !item.required!.bool : true
        
        
        if let slf = self as? QuestionnaireItemStep {
            
            if let q = item.text?.localized {
                slf.question = q
                slf.text = item.sm_questionItem_instructions()
            }
            else {
                throw SMError.instrumentQuestionnaireMissingText(linkId: linkId)
            }
        }
        else if let slf = self as? SMInstructionStep {
            slf.isOptional = false
//            slf.text = " "
            slf.detailText = " "
//            slf.footnote = ""
            slf.text =  " "
            let text_attributed = item.text?.sm_xhtmlAttributedText()
            let text = item.text?.localized
            let instructions = item.sm_questionItem_instructions()
            if text_attributed != nil {
                // Ignore item.text
                slf.attributedBodyString = text_attributed
                slf.text = instructions
            }
            else {
                slf.text = instructions
                slf.detailText = text
            }
        }
        else if let slf = self as? ORKWebViewStep {
            
            if let xhtml = item.text?.extensions(forURI: kSD_QuestionnaireItemRenderingXhtml)?.first?.valueString?.string {
                slf.html = xhtml
            }
            else {
                slf.html = item.text?.localized ?? item.sm_questionItem_instructions()
            }
        }
        
        else if let slf = self as? QuestionnaireFormStep {

//            slf.text = item.text?.string
//            slf.text = item.id?.string
            slf.detailText = item.sm_questionItem_instructions()
            slf.isOptional = (item.required?.bool != nil) ? !item.required!.bool : true
        }
        
        if #available(iOS 15.0, *) {
            
            if self.text == nil {
                self.text = " "
            }
            else if self.text!.last != "\n" {
                self.text! += "\n"
            }
            if self.detailText == nil {
                self.detailText = " "
            }
            else if self.detailText!.last != "\n" {
                self.detailText! += "\n"
            }
        }
        

    }
    
    var stepIdentifier: String {
        identifier
    }
    
}

class ItemInstructionStep: SMInstructionStep, QuestionnaireItemStepProtocol {
    
    var type: String?
    
    var result: ORKResult?
    
    
    
}

public class QuestionnaireItemInstructionStep: ORKInstructionStep, QuestionnaireItemStepProtocol {
    
    public var type: String?
    
    public var result: ORKResult?
    
    
}

public class QuestionnaireItemStep: ORKQuestionStep, QuestionnaireItemStepProtocol {
    
    public var type: String?
    
    public var result: ORKResult?
    
    public override func stepViewControllerClass() -> AnyClass {
        QuestionItemStepViewController.self
    }
    
}

class QuestionItemStepViewController: ORKQuestionStepViewController {
    
    private var fixCheck = 0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fix()
    }

    func fix() {
        for v in self.view.subviewsRecursive() {
            if let n = v as? ORKNavigationContainerView {
                n.skipButton.setAppearanceAsTextButton()
                n.continueButton.resetAppearanceAsBorderedButton()
                n.updateContinueAndSkipEnabled()
                n.skipButton.setAppearanceAsBoldTextButton()
            }
        }
        fixCheck += 1
    }
}

public class QuestionnaireFormStep: ORKFormStep, QuestionnaireItemStepProtocol {
    
    public var type: String?
    
    public var result: ORKResult?
    
    public override func stepViewControllerClass() -> AnyClass {
        QuestionnaireItemFormViewController.self
    }
}

public class QuestionnaireItemFormViewController: ORKFormStepViewController {
    
    private var fixCheck = 0
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fix()
    }

    func fix() {
        for v in self.view.subviewsRecursive() {
            if let n = v as? ORKNavigationContainerView {
                n.skipButton.setAppearanceAsTextButton()
                n.continueButton.resetAppearanceAsBorderedButton()
                n.updateContinueAndSkipEnabled()
                n.skipButton.setAppearanceAsBoldTextButton()
            }
        }
        fixCheck += 1
    }
}

open class SMLearnMoreInstructionStep: ORKLearnMoreInstructionStep {
    
    public var attributedBodyString: NSAttributedString? {
        willSet {
            text = " "
            detailText = " "
        }
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        SMLearnMoreStepViewController.classForCoder()
    }
}
open class SMLearnMoreStepViewController: ORKLearnMoreStepViewController  {
   
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fixattributedText()
    }
    func fixattributedText() {
        let stp = self.step as! SMLearnMoreInstructionStep
        if let attributedString = stp.attributedBodyString {
            let textLabel = self.view.subviewsRecursive().filter({ $0.isKind(of: ORKLabel.self) })[2] as! ORKLabel
            textLabel.attributedText  = attributedString
            textLabel.setNeedsLayout()
            textLabel.setNeedsDisplay()
        }
        

    }
}


public class SMInstructionStep: ORKInstructionStep {
    public var attributedBodyString: NSAttributedString? {
        willSet {
            text = " "
            detailText = " "
        }
    }
    public override func stepViewControllerClass() -> AnyClass {
        SMInstructionStepViewController.self
    }
}
class SMInstructionStepViewController: ORKInstructionStepViewController {
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fixattributedText()
    }
    
    /*
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        justDoThis()
        

        
    }

    
    override func viewLayoutMarginsDidChange() {
        justDoThis()

        super.viewLayoutMarginsDidChange()

    }

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        justDoThis()

    }*/
        
    
    
    
    func fixattributedText() {
        
        
        let stp = self.step as! SMInstructionStep
        if let attributedString = stp.attributedBodyString {
            let textLabel = self.view.subviewsRecursive().filter({ $0.isKind(of: ORKLabel.self) })[2] as! ORKLabel
            textLabel.attributedText  = attributedString
            textLabel.setNeedsLayout()
            textLabel.setNeedsDisplay()
        }
        

    }
    
}
extension UIView {

    func subviewsRecursive() -> [UIView] {
        return subviews + subviews.flatMap { $0.subviewsRecursive() }
    }

}

