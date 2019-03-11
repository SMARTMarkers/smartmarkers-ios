//
//  FHIRDefinitions.swift
//  EASIPRO
//
//  Created by Raheel Sayeed on 8/6/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import Foundation


/// Structure Definition to resolve `Questionnaire` reference embedded in `ProcedureRequest`
let kStructureDefinition_QuestionnaireRequest = "http://hl7.org/fhir/StructureDefinition/procedurerequest-questionnaireRequest"
let kStructureDefinition_QuestionnaireInstruction = "http://hl7.org/fhir/StructureDefinition/questionnaire-instruction"
let kStructureDefinition_QuestionnaireHelp = "http://hl7.org/fhir/StructureDefinition/questionnaire-help"
let kStructureDefinition_QuestionnaireCalculatedExpression = "http://hl7.org/fhir/StructureDefinition/questionnaire-calculatedExpression"

/// Coding Systems - LOINC
let kLoincSystemKey = "http://loinc.org"


/// Adaptive QuestionnaireResponse SDC Defs
let kSDC_adaptive_QuestionnaireResponse = "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt"
let kSDC_adaptive_QuestionnaireExpiration = "http://hl7.org/fhir/StructureDefinition/questionnaire-expirationTime"
let kSDC_adaptive_QuestionnaireFinished = "http://hl7.org/fhir/StructureDefinition/questionnaire-finishedTime"


/// Adaptive Questionnaire SDC Dynamic
let kSDC_adaptive_Questionnaire_Dynamic = "http://hl7.org/fhir/us/sdc/StructureDefinition/sdc-questionnaire-dynamic"
let kSDC_adaptive_Questionnaire = "http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-adapt"

let kStructureDefinition_QuestionnaireResponseScores = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores"
let kStructureDefinition_QuestionnaireResponseScoresTheta = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores/theta"
let kStructureDefinition_QuestionnaireResponseScoresDeviation = "http://hl7.org/fhir/StructureDefinition/questionnaire-scores/deviation"
