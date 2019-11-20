//
//  OmronTaskViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 3/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART


open class OMRONStep: WebFetchStep {
    
    init(auth: OAuth2) {
        super.init("OMRONFetchStep", title: "OMRON Blood Pressure", auth:  auth)
        self.request = URLRequest(url: URL(string: "https://ohi-api.numerasocial.com/api/measurement")!)
        request?.httpMethod = "POST"
        request?.httpBody = "since=2016-03-03".data(using: .utf8)
    
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func stepViewControllerClass() -> AnyClass {
        return OmronStepViewController.self
    }

    open override func resultFromFetch(json: [String : Any]?) -> ORKResult? {
        if let result = json?["result"] as? [String: Any] {
            if let bps = result["bloodPressure"] as? [[String: Any]] {
                if let firstItm = bps.first {
                    let systolic = firstItm["systolic"] as! Int
                    let diastolic = firstItm["diastolic"] as! Int
                    let datetime = firstItm["dateTime"] as! String
                    let orkresult = ORKResult(identifier: self.identifier)
                    orkresult.userInfo = ["datetime": datetime, "systolic": systolic, "diastolic": diastolic, "device": "omron"]
                    return orkresult
                }
            }
        }
        return nil
    }
}

open class OmronStepViewController: WebFetchStepViewController {
    
    public var omron: OMRONStep {
        return self.step as! OMRONStep
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.step?.text = needsAuthorization  ?
            "This app needs authorization to access data from the Omron Wellness portal. After authorization, the app will fetch the most recent Blood Pressure recording and present for approval for submission to your health record.\n\nTap Learn More for details on privacy prolicy"
            :
        "Please wait... \nFetching most recent blood pressure record"
        
        self.continueButtonTitle = (needsAuthorization) ? "Needs Authorization" : (omron.hasResult) ? "Submit" : "Continue"
        
        omron.onSuccessCallback = { (result, json) in
            if let result = result {
                self.addResult(result)
            }
            if let json = json {
                self.configureUI(json)
            }
        }
    }
    
    func configureUI(_ json: [String:Any]) {
        if let result = json["result"] as? [String: Any] {
            if let bps = result["bloodPressure"] as? [[String: Any]] {
                if let firstItm = bps.first {
                    let systolic = firstItm["systolic"] as! Int
                    let diastolic = firstItm["diastolic"] as! Int
                    let datetime = firstItm["dateTime"] as! String
                    let deviceType = firstItm["deviceType"] as! String
                    let recordId = firstItm["id"] as! Int
                    self.omron.items = [
                        ("Record ID         : \(recordId)" as NSCopying & NSSecureCoding & NSObject),
                        ("Blood Pressure    : \(systolic)/\(diastolic) mmHg" as NSCopying & NSSecureCoding & NSObject),
                        ("DateTime          : \(datetime)" as NSCopying & NSSecureCoding & NSObject),
                        ("DeviceType        : \(deviceType)" as NSCopying & NSSecureCoding & NSObject)
                    ]
                    self.omron.text = "Fetch complete"
                    self.continueButtonTitle = "Submit"
                    self.tableView.reloadData()
                    self.updateButtonStates()
                }
            }
        }
    }
}

open class OmronTaskViewController: ORKTaskViewController {
    
    
    public init(auth: OAuth2) {
        
        let introStep = ORKInstructionStep(identifier: "intro", _title: "OMRON Blood Pressure", _detailText: "This task will guide you through the process of securely fetching your latest Blood Pressure saved in your OMRON Cloud Account.\n\nNext steps:\n\n1. Will seek your authorization to access the Blood Pressure data\n\n2. Select which records you want to submit.\n\n3. Submission Report")
        
        let success = ORKCompletionStep(identifier: "success", _title: "OMRON Blood Pressure", _detailText: "Successfully retrieved blood pressure record.\n\nThank you.")
        
        let omronStep = OMRONStep(auth: auth)
        
        let steps = [introStep, omronStep, success]
        
        let task = ORKOrderedTask(identifier: "taskId", steps: steps)
        
        super.init(task: task, taskRun: UUID())
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
