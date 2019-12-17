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



let kActivitydateSelectorStep = "smartmarkers.activity.step.dateselector"
let kActivityFetchStep        = "smartmarkers.activity.step.fetch"
let kAcitivtyCompletionStep   = "smartmarkers.activity.step.completion"
let kActivityTask             = "smartmarkers.activity.task"


open class ActivityReportTask: ORKNavigableOrderedTask {
    
    public weak var activity: Activity!
    
    public init(activity: Activity) {
        
        let introStep = ORKInstructionStep(identifier: "intro", _title: activity.type.description, _detailText: "This task will guide you through the process of  fetching your latest \(activity.type.description) saved in your Health app.\n\nNext steps:\n\n1. Will seek your authorization to access the Blood Pressure data\n\n2. Select which records you want to submit.\n\n3. Submission Report")

        self.activity  = activity
        let dateStep   = ActivityDateSelectorStep(activity)
        let fetchStep  = ActivityFetchStep(activity)
        let conclusion = ActivityCompletionStep(activity)
        
        let steps = [
            introStep,
            dateStep,
            fetchStep,
            conclusion
        ]
        
        let identifier = kActivityTask + ".\(activity.type)"
        super.init(identifier: identifier, steps: steps)
        setStepModifier(DateStepModifier(), forStepIdentifier: fetchStep.identifier)
        setStepModifier(ResultCheckStepModifier(), forStepIdentifier: conclusion.identifier)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public protocol ActivityStep: class {
    
    var activity: Activity? { get set }
    
}

open class ResultCheckStepModifier: ORKStepModifier {
    
    open override func modifyStep(_ step: ORKStep, with taskResult: ORKTaskResult) {

        let stp = step as! ActivityStep
        let identifier = kActivityFetchStep + ".\(stp.activity!.type)"
        if let stepSamples = taskResult.stepResult(forStepIdentifier: identifier)?.results as? [SMQuantitySampleResult] {
            for sample in stepSamples {
                print(sample)
            }
        }
    }
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
        self.title = "Select Date Range"
        self.text = "Select a start and an end date.\nActivity data which activity data should be fetched."
        let today = Date()
        let startItem = ORKFormItem(identifier: "start-date", text: "Start Date", answerFormat: ORKAnswerFormat.dateAnswerFormat())
        let endItem = ORKFormItem(identifier: "end-date", text: "End Date", answerFormat: ORKAnswerFormat.dateAnswerFormat(withDefaultDate: today, minimumDate: nil, maximumDate: today, calendar: nil))
        self.formItems = [startItem, endItem]
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open class ActivityCompletionStep: ORKCompletionStep, ActivityStep {
    
    weak public var activity: Activity?
    
    required public init(_ activity: Activity) {
        super.init(identifier: kAcitivtyCompletionStep)
        self.activity = activity
        self.title = activity.type.description
        self.detailText = "Completed"
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class ActivityFetchStep: ORKWaitStep, ActivityStep {
    
    weak public var activity: Activity?
    
    public init(_ activity: Activity) {
        
        let identifier = kActivityFetchStep + ".\(activity.type)"

        super.init(identifier: identifier)
        self.activity = activity
        self.text = "Gathering data, please wait..."
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
        
        let stp = (self.step as! ActivityFetchStep)
        let store = HKHealthStore()

        let group = DispatchGroup()
        
        group.enter()
        stp.activity?.fetch(store, callback: { [weak self] (samples, error) in
            if let samples = samples as? [HKQuantitySample] {
                let sampleType = stp.activity!.type.description
                let result = SMQuantitySampleResult(sampleType: sampleType, samples: samples)
                stp.activity?.value = result as Any
                self?.addResult(result)
            }
            group.leave()
        })
        
        group.notify(queue: .main) {
            self.goForward()
        }
    }
}

open class ActivityTaskViewController: InstrumentTaskViewController {
    
    public init(activityTask: ActivityReportTask) {
        super.init(task: activityTask, taskRun: UUID())
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


