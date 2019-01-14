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
    
    var ip_title: String { get }
    
    var ip_identifier: String { get }
    
    var ip_code: SMART.Coding? { get }
    
    var ip_version: String? { get }
    
    func ip_generateSteps(callback: @escaping ((_ steps : [ORKStep]?, _ error: Error?) -> Void))
    
    func ip_navigableRules(for steps:[ORKStep]?, callback: ((_ rules: [ORKStepNavigationRule]?, _ error: Error?) -> Void))
    
    /// Protocol Func to generate ResearchKit's `ORKTaskViewController`
    func ip_taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void))
    
    /// Protocol Func to generate a FHIR `Bundle` of result resources. eg. QuestionnaireResponse, Observation
    func ip_generateResponse(from result: ORKTaskResult, task: ORKTask) -> SMART.Bundle?
    
}


open class InstrumentResource : InstrumentResourceProtocol {
    
    public var title: String {
        return instrument.ip_title
    }
    
    public var identifier: String {
        return instrument.ip_identifier
    }
    
    public var code: Coding? {
        return instrument.ip_code
    }
    
    public var version: String? {
        return instrument.ip_version
    }
    
    public weak var _prescriber: PrescriberType?
    
    public var instrument: (InstrumentProtocol)
    
    public required init(_ _instrument: InstrumentProtocol) {
        instrument = _instrument
    }
    
    public func taskController(for measure: PROMeasure, callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
        instrument.ip_taskController(for: measure) { (taskViewController, error) in
            if let taskViewController = taskViewController {
                callback(taskViewController, nil)
            }
            else {
                callback(nil, SMError.instrumentTaskViewControllerNotCreated)
            }
        }
        
    }
    
    public func generateResponse(from result: ORKTaskResult, task: ORKTask) throws ->  SMART.Bundle {
        
        if let bundle = instrument.ip_generateResponse(from: result, task: task) {
            return bundle
        }
        else {
            throw SMError.instrumentResultBundleNotCreated
        }
    }


    
}






