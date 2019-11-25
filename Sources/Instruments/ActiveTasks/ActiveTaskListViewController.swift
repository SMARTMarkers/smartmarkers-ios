//
//  ActiveTaskListViewController.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/21/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

/**
 Separate List for ActiveTasks supported by the framework.
 */
open class ActiveTaskListViewController: InstrumentListViewController {
    
    public convenience init() {
        self.init(server: nil)
    }
    
    open override func loadQuestionnaires() {
        if nil != instruments { return }
        title = "Active Tasks"
        markBusy()
        self.set(Instruments.ActiveTasks.allCases.map { $0.instance })
        markStandby()
    }
}
