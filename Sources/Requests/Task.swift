//
//  Task.swift
//  SMARTMarkers
//
//  Created by raheel on 4/1/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


extension SMART.Task: Request {
    public var rq_schedule: TaskSchedule? {
        get {
            nil
        }
        set {
            
        }
    }
    
    
    public var rq_identifier: String {
        self.id!.string
    }
    
    public var rq_title: String? {
        nil
    }
    
    public var rq_requesterName: String? {
        nil
    }
    
    public var rq_code: SMART.Coding? {
        nil
    }
    
    public var rq_requesterEntity: String? {
        nil
    }
    
    public var rq_requestDate: Date? {
        nil
    }
    
    public var rq_categoryCode: String? {
        nil
    }
    
    public static var rq_fetchParameters: [String : String]? {
        nil

    }
    
    public var rq_instrumentMetadataQuestionnaireReferenceURL: URL? {
        nil
    }
    
    public func rq_updated(_ completed: Bool, callback: @escaping ((Bool) -> Void)) {

        callback(false)
    }
    
    public func rq_resolveInstrument(callback: @escaping (((any Instrument)?, (any Error)?) -> Void)) {

        callback(nil, nil)
        
        
    }
    
    public func rq_resolveReferences(callback: @escaping ((Bool) -> Void)) {
        callback(false)
    }
    
    public func rq_configureNew(for instrument: any Instrument, schedule: TaskSchedule?, patient: SMART.Patient?, practitioner: SMART.Practitioner?) throws {
        
    }
    
    
    
    
}
