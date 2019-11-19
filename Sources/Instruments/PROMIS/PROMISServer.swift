//
//  ACModel.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 7/10/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation


public class PROMISClient {
   
    public var server: AdaptiveServer!
    
    public init(baseURL: URL, client_id: String, client_secret: String) {
        server = AdaptiveServer(baseURL: baseURL, auth: ["client_id": client_id, "client_secret": client_secret])
        
    }
    
    public func getInstruments(callback: @escaping ((_ instruments: [Instrument]?, _ error: Error?) -> Void)) {
        server.discover { (questionnaires, error) in
            if let questionnaires = questionnaires {
                callback(questionnaires, nil)
            }
            else {
                callback(nil, error)
            }
        }
    }
}
