//
//  AdaptiveQuestionnaireTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/28/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class AdaptiveQuestionnaireTaskViewController: ORKTaskViewController {
    
    public var adaptiveServer: FHIRServer? {
        didSet {
            adaptTask.adaptiveServer = adaptiveServer
        }
    }
    
    public var adaptTask: AdaptiveQuestionnaireTask {
        return task as! AdaptiveQuestionnaireTask
    }
    
    open override func stepViewControllerHasNextStep(_ stepViewController: ORKStepViewController) -> Bool {
        return stepViewController.step?.identifier != Step.Conclusion.rawValue
    }
    
    open override func stepViewControllerHasPreviousStep(_ stepViewController: ORKStepViewController) -> Bool {
        if stepViewController.step?.identifier == Step.Conclusion.rawValue || stepViewController.step?.identifier == Step.Introduction.rawValue {
            return false
        }
        return super.stepViewControllerHasPreviousStep(stepViewController)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    open override func stepViewControllerResultDidChange(_ stepViewController: ORKStepViewController) {
        super.stepViewControllerResultDidChange(stepViewController)
    }
    
    open override func stepViewController(_ stepViewController: ORKStepViewController, didFinishWith direction: ORKStepViewControllerNavigationDirection) {
        
        if direction == .reverse {
            self.adaptTask.stepBack()
        }
        
        super.stepViewController(stepViewController, didFinishWith: direction)
    }
}

