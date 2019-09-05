//
//  9HolePeg+InstrumentProtocol.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 3/15/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


open class NineHolePegTestPRO: InstrumentProtocol {
    
    public var ip_title: String {
        return "9 Hole Peg Test"
    }
    
    public var ip_identifier: String {
        return "9-hole-peg-test"
    }
    
    public var ip_code: Coding? {
        return nil
    }
    
    public var ip_version: String? {
        return nil
    }
    
    public var ip_resultingFhirResourceType: [FHIRSearchParamRelationship]? {
        return nil
    }
    
    public func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        
        let tsk = ORKNavigableOrderedTask.holePegTest(withIdentifier: ip_identifier, intendedUseDescription: nil, dominantHand: .right, numberOfPegs: 9, threshold: 0.2, rotated: false, timeLimit: 300, options: [])
        let tvc = ORKTaskViewController(task: tsk, taskRun: UUID())
        callback(tvc, nil)
    }
    
    public func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle? {
        return nil
    }
    
    
    
    
}
