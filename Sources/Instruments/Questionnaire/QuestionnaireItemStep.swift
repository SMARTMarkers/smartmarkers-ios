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
//			slf.text = " "
			slf.detailText = " "
//			slf.footnote = ""
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
	
}

public class QuestionnaireFormStep: ORKFormStep, QuestionnaireItemStepProtocol {
    
    public var type: String?
    
    public var result: ORKResult?
	
	public override func stepViewControllerClass() -> AnyClass {
		QuestionnaireItemFormViewController.self
	}
}

public class QuestionnaireItemFormViewController: ORKFormStepViewController {

}

open class SMLearnMoreInstructionStep: ORKLearnMoreInstructionStep {
	
	public var attributedBodyString: NSAttributedString?
	
	public override func stepViewControllerClass() -> AnyClass {
		SMLearnMoreStepViewController.classForCoder()
	}
}
class SMLearnMoreStepViewController: ORKLearnMoreStepViewController {
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
	}

	/*
	override func viewDidLoad() {
		super.viewDidLoad()
		print(step?.title)
		print(stepView?.instructionStep.attributedDetailText)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		fix()
		print(step?.title)

		

		
	}

	
	override func viewLayoutMarginsDidChange() {
		fix()

		super.viewLayoutMarginsDidChange()

	}

	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
		fix()
	}

		
	func fix() {
		let stp = self.step as! SMLearnMoreInstructionStep
		stp.text = " "
		stp.detailText = " "
		
		print(stp.attributedBodyString)
		print(stp.attributedDetailText)
		
		if let attributedString = stp.attributedBodyString {
			let textLabel = self.view.subviewsRecursive().filter({ $0.isKind(of: ORKLabel.self) })[2] as! ORKLabel
			print(attributedString)
			textLabel.attributedText  = attributedString
			textLabel.setNeedsLayout()
			textLabel.setNeedsDisplay()
		}
	}
*/
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

	}
		
	
	
	
	func justDoThis() {
		
		
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
