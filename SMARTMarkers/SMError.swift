//
//  SMError.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 1/9/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

public enum SMError : Error, CustomStringConvertible {
    
    case undefined
    
    // Mark: PROServer
    
    /// PROServer User Is not Practitioner or Patient
    case proserverUserNotPractitionerOrPatient(profileType: String)
    
    /// PROServer cannot handle FHIR Profile
    case proserverMissingUserProfile
    
    
    // MARK: PROMeasure
    
    /// PROMeasure is missing ordered Instrument
    case promeasureOrderedInstrumentMissing

    /// `PROMeasure.server` is nil
    case promeasureServerNotSet
    
    /// `PROMeasure.fetchAll()` error in fetching links
    case promeasureFetchLinkedResources
    
    
    // MARK: ReportProtocol
    
    /// Report could not be submitted
    case reportSubmissionToServerError(serverError: Error)
    
    /// FHIR Resources received are not `ReportProtocol` conformant
    case reportUnknownFHIRReportType
    
    // MARK: InstrumentProtocol
    
    /// InstrumentProtocol could not generate TaskViewController
    case instrumentTaskViewControllerNotCreated
    
    /// InstrumentProtocol could not generate a response `SMART.Bundle`
    case instrumentResultBundleNotCreated
    
    /// Instrument could not deduce answer type
    case instrumentCannotHandleQuestionnaireType(linkId: String)
    
    /// QuestionnaireItem type missing
    case instrumentQuestionnaireTypeMissing(linkId: String)
    
    /// Questionnaire Item missing question text
    case instrumentQuestionnaireMissingText(linkId: String)
    
    /// Questionnaire does not have `Items`
    case instrumentQuestionnaireMissingItems(linkId: String)
    
    /// Questionnaire.items has duplicate linkIds
    case instrumentHasDuplicateLinkIds
    
    /// Questionnaire.type `choice` should have answer options
    case instrumentQuestionnaireItemMissingOptions(linkId: String)
    
    /// Questionnaire Missing Calculated Expression
    case instrumentQuestionnaireMissingCalculatedExpression(linkId: String)
    
    /// HealthKit Resource Type not supported
    case instrumentHealthKitClinicalRecordTypeNotSupported(type: String)
    
    // Mark: SessionController
    
    /// SessionController has no taskViewControllers
    case sessionMissingTask
    
    /// SessionController created with some missing Tasks
    case sessionCreatedWithMissingTasks
    
    
    
    // Mark: AdaptiveQuestionnaires
    
    /// Error Mapping Questionnaires from R4 to STU3
    case adaptiveQuestionnaireErrorMappingToSTU3
    
    /// QuestionnarieResponse already completed, cannot get perform `next-q` operation
    case adaptiveQuestionnaireAlreadyCompleted
    
    
    
    
    
    public var description: String {
        
        switch self {
            
        case .undefined:
            return "Undefined"
        // AdaptiveQuestionnaires
            
        case .adaptiveQuestionnaireErrorMappingToSTU3:
            return "AdaptiveQuestionnaire: Error mapping to STU3"
        case .adaptiveQuestionnaireAlreadyCompleted:
            return "AdaptiveQuestionnaire: Already completed; cannot perform next-q operation"
        
        // PROServer
            
        case .proserverMissingUserProfile:
            return "PROServer.idToken: Missing Profile- Patient or Practitioner"
        case .proserverUserNotPractitionerOrPatient(let profileType):
            return "PROServer cannot handle FHIR Profile Type `\(profileType)`"
            
        // PROMEasure
            
        case .promeasureOrderedInstrumentMissing:
            return "PROMeasure.orderedInstrument is uninitialized. check"
        case .promeasureServerNotSet:
            return "PROMeasure.server is nil, cannot perform server functions"
        case .promeasureFetchLinkedResources:
            return "PROMeasure: error encountered fetching resources from server"
            
        // Reports
            
        case .reportSubmissionToServerError(let serverError):
            return "Reports could not be submitted to the FHIR Server \(serverError)"
        case .reportUnknownFHIRReportType:
            return "FHIR resources retrieved are not conformant to ReportProtocol"
            
        // Instrument
            
        case .instrumentQuestionnaireTypeMissing(let linkId):
            return "Instrument-Questionnaire: type missing for item `linkId`: \(linkId)"
        case .instrumentTaskViewControllerNotCreated:
            return "Instrument could not generate TaskViewController"
        case .instrumentResultBundleNotCreated:
            return "InstrumentProtocol could not generate a response `SMART.Bundle`"
        case .instrumentCannotHandleQuestionnaireType(let linkId):
            return "InstrumentProtocol could not create step for QuestionnaireItem.type for linkId: \(linkId)"
        case .instrumentQuestionnaireMissingItems(let linkId):
            return "`Questionnaire.item` is empty for linkId: \(linkId)"
        case .instrumentQuestionnaireMissingText(let linkId):
            return "`Questionnaire.item` is missing a question text; linkId: \(linkId)"
        case .instrumentHasDuplicateLinkIds:
            return "Questionnaire.item.linkId(s) should be unique"
        case .instrumentQuestionnaireItemMissingOptions(let linkId):
            return "Questionnaire.item.type = choice  must have answer reference for linkId: \(linkId)"
        case .instrumentHealthKitClinicalRecordTypeNotSupported(let type):
            return "HealthKit Clinical Record type `\(type)` not supported"
        
        // SessionController
        case .sessionMissingTask:
            return "SessionController cannot be created, no `TaskViewController`(s) found"
        case .sessionCreatedWithMissingTasks:
            return "SessionController created with some missing Tasks"
        case .instrumentQuestionnaireMissingCalculatedExpression(let linkId):
            return "Questionnaire.item is missing calculated expression for linkId: \(linkId)"
        }
        
    }
    
    
}
