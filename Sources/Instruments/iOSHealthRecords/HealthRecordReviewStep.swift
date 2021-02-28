//
//  HealthRecordReviewStep.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 2/24/21.
//  Copyright © 2021 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART



@available(iOS 12.0, *)
class HealthRecordReviewStep: ORKFormStep {
    
    
    override init(identifier: String) {
        
        super.init(identifier: identifier)
        self.footnote = ""
        self.isOptional = false
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI(records: [HealthRecordResult]) {
        
        // filter Clinical Record Result which has have atleast more than one health record
        
        let filtered = records.filter { (result) -> Bool in
            return (result.records?.count ?? 0 > 0)
        }
        
        if filtered.count > 0 {
            self.text = "The following set(s) of health records have been retrieved from your iPhone (Health app)\nPlease select data for import into the app"
            let choices    = filtered.map { $0.textChoice() }
            let reviewChoices = ORKAnswerFormat.choiceAnswerFormat(with: .multipleChoice, textChoices: choices)
            let items = ORKFormItem(identifier: "clinicalrecords", text: nil, answerFormat: reviewChoices)
              items.isOptional = true
            self.formItems = [items]
        }
        else {
            self.text = "Health Records could not be retrieved"
            self.formItems = nil
        }
    }
}
