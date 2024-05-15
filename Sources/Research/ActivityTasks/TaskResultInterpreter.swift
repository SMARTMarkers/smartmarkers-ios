//
//  TaskResultInterpreter.swift
//  SMARTMarkers
//
//  Created by raheel on 4/9/24.
//  Copyright © 2024 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public protocol TaskResultInterpreterProtocol {
   
    var summary: String? { get set }
    var caution: String? { get set }
    var notes: [String]? { get set }
    var mustRepeat: Bool { get set }
    var result: StudyTaskResult { get set }
    init(result: StudyTaskResult)
    func fulfilled() -> Bool
    func communication<T: DomainResource>() -> T?
    func resolve(condition: PlanDefinitionActionCondition) -> Any?
}

public extension TaskResultInterpreterProtocol {
    
    var fhir: [DomainResource]? {
        result.fhir
    }
    
}
