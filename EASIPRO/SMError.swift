//
//  SMError.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 1/9/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

public enum SMError : Error, CustomStringConvertible {
    
    // Mark: PROServer
    
    /// PROServer not ready
    
    
    // MARK: PROMeasure
    
    /// PROMeasure is missing ordered Instrument
    case promeasureOrderedInstrumentMissing

    /// `PROMeasure.server` is nil
    case promeasureServerNotSet
    
    /// `PROMeasure.fetchAll()` error in fetching links
    case promeasureFetchLinkedResources
    
    
    
    // MARK: InstrumentProtocol
    
    /// InstrumentProtocol could not generate TaskViewController
    case instrumentTaskViewControllerNotCreated
    
    /// InstrumentProtocol could not generate a response `SMART.Bundle`
    case instrumentResultBundleNotCreated
    
    /// Instrument could not deduce answer type
    case instrumentCannotHandleQuestionnaireType(linkId: String)
    
    /// QuestionnaireItem type missing
    case instrumentQuestionnaireTypeMissing(linkId: String)
    
    
    // Mark: SessionController
    
    /// SessionController has no taskViewControllers
    case sessionMissingTask
    
    /// SessionController created with some missing Tasks
    case sessionCreatedWithMissingTasks
    
    
    
    
    public var description: String {
        
        switch self {
            
        case .promeasureOrderedInstrumentMissing:
            return "PROMeasure.orderedInstrument is uninitialized. check"
        case .promeasureServerNotSet:
            return "PROMeasure.server is nil, cannot perform server functions"
        case .promeasureFetchLinkedResources:
            return "PROMeasure: error encountered fetching resources from server"
            
        case .instrumentQuestionnaireTypeMissing(let linkId):
            return "Instrument-Questionnaire: type missing for item `linkId`: \(linkId)"
        case .instrumentTaskViewControllerNotCreated:
            return "Instrument could not generate TaskViewController"
        case .instrumentResultBundleNotCreated:
            return "InstrumentProtocol could not generate a response `SMART.Bundle`"
        case .instrumentCannotHandleQuestionnaireType(let linkId):
            return "InstrumentProtocol could not create step for QuestionnaireItem.type for linkId: \(linkId)"
        
        case .sessionMissingTask:
            return "SessionController cannot be created, no `TaskViewController`(s) found"
        case .sessionCreatedWithMissingTasks:
            return "SessionController created with some missing Tasks"
        }
        
    }
    
    
}
