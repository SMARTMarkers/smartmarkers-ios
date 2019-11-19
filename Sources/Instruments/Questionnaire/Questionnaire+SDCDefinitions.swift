//
//  Questionnaire+SDCDefinitions.swift
//  SMARTMarkers
//
//  Created by Raheel Sayeed on 9/13/19.
//  Copyright © 2019 Boston Children's Hospital. All rights reserved.
//

import Foundation

/// Structure Definition to resolve `Questionnaire` reference embedded in `ServiceRequest`
let kSD_QuestionnaireRequest = "http://hl7.org/fhir/StructureDefinition/servicerequest-questionnaireRequest"
let kSD_QuestionnaireInstruction = "http://hl7.org/fhir/StructureDefinition/questionnaire-instruction"
let kSD_QuestionnaireHelp = "http://hl7.org/fhir/StructureDefinition/questionnaire-help"
let kSD_QuestionnaireCalculatedExpression = "http://hl7.org/fhir/StructureDefinition/questionnaire-calculatedExpression"

/// Adaptive QuestionnaireResponse SDC Defs
let kSD_adaptive_QuestionnaireExpiration = "http://hl7.org/fhir/StructureDefinition/questionnaire-expirationTime"
let kSD_adaptive_QuestionnaireFinished = "http://hl7.org/fhir/StructureDefinition/questionnaire-finishedTime"
let kSD_QuestionnaireResponseItemOrder = "http://hl7.org/fhir/StructureDefinition/questionnaire-displayOrder"

/// Adaptive Questionnaire SDC Dynamic
let kSD_adaptive_Questionnaire_Dynamic = "http://hl7.org/fhir/us/sdc/StructureDefinition/sdc-questionnaire-dynamic"
let kSD_adaptive_Questionnaire = "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-adapt"
let kSD_adaptive_QuestionnaireResponse = "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt"

/// Adaptive QuestionnaireResponse SDC Dynamic
let kSD_QuestionnaireResponseScores = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores"
let kSD_QuestionnaireResponseScoresTheta = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores/theta"
let kSD_QuestionnaireResponseScoresStandardError = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores/standarderror"


// ValueSets

let kVS_YesNoDontknow = "http://hl7.org/fhir/ValueSet/yesnodontknow"
