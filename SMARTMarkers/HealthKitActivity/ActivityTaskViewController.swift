//
//  ActivityTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 10/3/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import HealthKit



let kActivitydateSelectorStep = "kSM.activity.date.selector"
let kActivityFetchStep        = "kSM.activity.fetch"
let kActivityTask             = "kSM.activity.task"


open class ActivityReportTask: ORKNavigableOrderedTask {
    
    public final let activity: Activity!
    
    public init(activity: Activity) {
        
        self.activity  = activity
        let dateStep   = ActivityDateSelectorStep(activity)
        let fetchStep  = ActivityFetch(activity)
        let conclusion = ORKCompletionStep(identifier: ksm_step_completion, _title: "Completed", _detailText: nil)
        
        let steps = [
            dateStep,
            fetchStep,
            conclusion
        ]
        
        let identifier = kActivityTask + ".\(activity.type)"
        super.init(identifier: identifier, steps: steps)
        setStepModifier(DateStepModifier(), forStepIdentifier: fetchStep.identifier)
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public protocol ActivityStep: class {
    
    var activity: Activity? { get set }
    
}

open class DateStepModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {
        
        let stp = step as! ActivityStep
        let identifier = kActivitydateSelectorStep + ".\(stp.activity!.type)"
        if let dates = taskResult.stepResult(forStepIdentifier: identifier)?.results as? [ORKDateQuestionResult] {
            
            for date in dates {
                if date.identifier == "start-date" {
                    stp.activity?.period?.start = date.dateAnswer
                }
                else {
                    stp.activity?.period?.end = date.dateAnswer
                }
            }
        }
    }
}

open class ActivityDateSelectorStep: ORKFormStep, ActivityStep {
    
    weak public var activity: Activity?
    
    convenience init(_ activity: Activity) {
        
        let identifier = kActivitydateSelectorStep + ".\(activity.type)"
        self.init(identifier: identifier)
    }
    
    override public init(identifier: String) {
        super.init(identifier: identifier)
        
        let today = Date()
        let startItem = ORKFormItem(identifier: "start-date", text: "Start Date", answerFormat: ORKAnswerFormat.dateAnswerFormat())
        let endItem = ORKFormItem(identifier: "end-date", text: "End Date", answerFormat: ORKAnswerFormat.dateAnswerFormat(withDefaultDate: today, minimumDate: nil, maximumDate: today, calendar: nil))
        self.formItems = [startItem, endItem]
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class ActivityFetch: ORKWaitStep, ActivityStep {
    
    weak public var activity: Activity?
    
    public init(_ activity: Activity) {
        
        let identifier = kActivityFetchStep + ".\(activity.type)"

        super.init(identifier: identifier)
        self.activity = activity
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return ActivityFetchStepController.self
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class ActivityFetchStepController: ORKWaitStepViewController {
    
    open override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        
        let stp = (self.step as! ActivityFetch)
        let store = HKHealthStore()
        print(stp.activity?.period)
        
        stp.activity?.fetch(store, callback: { [weak self] (samples, error) in
            
            if let samples = samples as? [HKQuantitySample] {
                let sampleType = stp.activity!.type.description
                let result = SMQuantitySampleResult(sampleType: sampleType, samples: samples)
                print(samples)
                self?.addResult(result)
                DispatchQueue.main.async {
                    //self?.addResult(result)
                }
            }
            
            DispatchQueue.main.async {
                self?.goForward()
            }
        })
    }
}

open class ActivityTaskViewController: ORKTaskViewController {
    
    public init(activity: Activity) {
        let task = ActivityReportTask(activity: activity)
        super.init(task: task, taskRun: UUID())
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public class SMQuantitySampleResult: ORKResult {
    
    var samples: [HKQuantitySample]?
    
    required convenience init(sampleType: String, samples: [HKQuantitySample]) {
        self.init(identifier: sampleType)
        self.samples = samples
    }
    
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(samples as Any, forKey: "samples")
    }
    
    override public func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone) as! SMQuantitySampleResult
        result.samples = samples
        return result
    }
}


