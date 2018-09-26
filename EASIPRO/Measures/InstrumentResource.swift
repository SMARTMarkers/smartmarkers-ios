//
//  InstrumentResource.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 6/28/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit

public protocol InstrumentResourceProtocol : class {
    
    
    var identifier : String { get }
    
    var code : Coding? { get }
    
    var instrument : InstrumentProtocol { get set }
    
    var _prescriber: PrescriberType? { get }
    
    init(_ instrument: InstrumentProtocol)

}


public protocol InstrumentProtocol : class {
    
    var rk_title: String { get }
    
    var rk_identifier: String { get }
    
    var rk_code: SMART.Coding? { get }
    
    var rk_version: String? { get }
    
    func rk_generateSteps(callback: @escaping ((_ steps : [ORKStep]?, _ error: Error?) -> Void))
    
    func rk_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
        
    func rk_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle?
    
}


open class InstrumentResource : InstrumentResourceProtocol {
    
    public var title: String {
        return instrument.rk_title
    }
    
    public var identifier: String {
        return instrument.rk_identifier
    }
    
    public var code: Coding? {
        return instrument.rk_code
    }
    
    public var version: String? {
        return instrument.rk_version
    }
    
    public weak var _prescriber: PrescriberType?
    
    public var instrument: (InstrumentProtocol)
    
    public required init(_ _instrument: InstrumentProtocol) {
        instrument = _instrument
    }
    
}






