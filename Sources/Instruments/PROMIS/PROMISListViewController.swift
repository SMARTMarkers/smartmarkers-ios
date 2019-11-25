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
public class PROMISListViewController: InstrumentListViewController {
    
    public var client: PROMISClient?
    
    public convenience init(client: PROMISClient) {
        self.init(server: client.server)
        self.client = client
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
