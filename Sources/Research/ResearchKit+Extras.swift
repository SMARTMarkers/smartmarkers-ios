//
//  ResearchKit+Extras.swift
//  SMARTMarkers
//
//  Created by raheel on 3/29/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit



open class PPMGLearnMoreStep: SMLearnMoreInstructionStep {
    
    public override func stepViewControllerClass() -> AnyClass {
        PPMGLearnMoreStepViewController.classForCoder()
    }
}

public extension ORKStepViewController {
    
    func ppmg_setNavigationDoneButton() {
        self.cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ppmg_doneTapped(_:)))
        self.internalDoneButtonItem = nil
    }
    @objc private func ppmg_doneTapped(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
}
open class PPMGLearnMoreStepViewController: SMLearnMoreStepViewController {
    
    func setDoneButton() {
        cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
    }
    
    @objc func doneTapped(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
    open override var cancelButtonItem: UIBarButtonItem? {
        get {
             super.cancelButtonItem
        }
        set {
            super.cancelButtonItem = newValue
        }
    }
    
}
open class PPMGInstructionStep: ORKInstructionStep {
    
    public enum RightButton { case doneButton, cancelButton, none }
    public var continueButtonTitle: String?
    public var rightButtonType: RightButton = .none
//    var showCancelButton: Bool = true
//    var showDoneButton: Bool = false
    
    public var attributedBodyString: NSAttributedString? {
        didSet {
            text = " "
            detailText = " "
        }
    }
    
    public override func stepViewControllerClass() -> AnyClass {
        PPMGInstructionStepViewController.self
    }
}

open class PPMGInstructionStepViewController: ORKInstructionStepViewController {
    
    func setDoneButton() {
        cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
    }

    @objc func doneTapped(_ sender: Any?) {
        dismiss(animated: true, completion: nil)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        bugfix()
    }

    
    open override func viewLayoutMarginsDidChange() {
        bugfix()
        super.viewLayoutMarginsDidChange()
    }

    open override func viewDidLoad() {
        
        super.viewDidLoad()
        switch (step as! PPMGInstructionStep).rightButtonType {
        case .cancelButton:
            self.cancelButtonItem = super.cancelButtonItem
            break
        case .doneButton:
            setDoneButton()
            break
        case .none:
            cancelButtonItem = nil
        }
        
        if let btntitle = (step as? PPMGInstructionStep)?.continueButtonTitle {
            self.continueButtonTitle = btntitle
        }

        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bugfix()
    }
    
    
    func bugfix() {
        let stp = self.step as! PPMGInstructionStep
        if let attributedString = stp.attributedBodyString {
            let textLabel = self.view.subviewsRecursive().filter({ $0.isKind(of: ORKLabel.self) })[2] as! ORKLabel
            textLabel.attributedText  = attributedString
            textLabel.setNeedsLayout()
            textLabel.setNeedsDisplay()
        }
    }
}



open class PPMGQuestionStep: ORKQuestionStep {

    open var allowBackNav: Bool = true
    open var showCancelButton: Bool = true
    open override func stepViewControllerClass() -> AnyClass {
        PPMGQuestionStepViewController.self
    }
    open override var allowsBackNavigation: Bool {
        allowBackNav
    }
}

class PPMGQuestionStepViewController: ORKQuestionStepViewController {

    override var cancelButtonItem: UIBarButtonItem? {
        get { (step as! PPMGQuestionStep).showCancelButton ? super.cancelButtonItem : nil }
        set { super.cancelButtonItem = newValue }
    }
    override func viewDidLoad() {
        if #available(iOS 15.0, *) {
            smLog("[temp-bugfix]: ORKQuestionStep return line check")
            if step?.text == nil {
                step?.text = " "
            }
        }
        super.viewDidLoad()
    }
    
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

open class NoBackButtonCompletionStep: ORKCompletionStep {
    
    override open var allowsBackNavigation: Bool {
        false
    }
}

/// Skips the current step.
open class SkipStepRule: ORKSkipStepNavigationRule {
    
    open override func stepShouldSkip(with taskResult: ORKTaskResult) -> Bool {
        true
    }
}


open class SetPasscodeTitle: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        step.title = "Set passcode to access this app"
    }
}


open class SMCompletionStep: ORKCompletionStep {
    var imgColor: UIColor?
    override open func stepViewControllerClass() -> AnyClass {
        SMCompletionStepViewController.self
    }
}
class SMCompletionStepViewController: ORKCompletionStepViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        checkmarkColor = (step as! SMCompletionStep).imgColor
    }
}

open class PDFTaskViewer: InstrumentTaskViewController, ORKTaskViewControllerDelegate {
    
    public func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.dismiss(animated: true, completion: nil)
    }
    
    override public init(task: ORKTask?, taskRun taskRunUUID: UUID?) {
        super.init(task: task, taskRun: taskRunUUID)
        self.delegate = self
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension ORKBodyItem {
    
    static func Bullet(_ text: String) -> ORKBodyItem {
        ORKBodyItem(text: text, detailText: nil, image: nil, learnMoreItem: nil, bodyItemStyle: .bulletPoint)
    }
}
