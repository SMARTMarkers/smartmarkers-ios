//
//  AssessmentCenterServer.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

/**
 Exclusive class to list `PROMIS` instruments
 */
public class PROMISListViewController: MeasuresViewController {
    
    public var client: PROMISClient?
    
    public required init(client: PROMISClient) {
        super.init(style: .plain)
        self.client = client
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func loadQuestionnaires() {
        if nil != instruments { return }
        title = "PROMIS CAT"
        markBusy()
        client?.getInstruments(callback: { [weak self] (instruments, error) in
            if let instruments = instruments {
                self?.set(instruments)
            }
            DispatchQueue.main.async {
                self?.markStandby()
            }
        })
    }
    
    
    
}
