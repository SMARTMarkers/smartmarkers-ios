//
//  AssessmentCenterServer.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 11/12/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

public class AssessmentCenterServer: AQServer {
    
    public convenience init(base: URL, clientid: String, clientsecret: String) {
        let settings = [
            "client_id" : clientid,
            "client_secret" : clientsecret
        ]
        self.init(baseURL: base, auth: settings)
    }
}
