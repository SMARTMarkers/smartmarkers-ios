//
//  SpatialSpanMemoryObservation.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 4/18/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public extension Observation {
    
    class func sm_SpatialSpanMemory(score: Int, date: Date, instrument: Instrument?) -> Observation {
        
        let observation = Observation()
        if let instr = instrument {
            observation.code = CodeableConcept.sm_From(instr)
        }
        observation.status = .final
        observation.effectiveDateTime = date.fhir_asDateTime()
        observation.valueString = FHIRString(String(score))
        
        return observation
    }
    
}

